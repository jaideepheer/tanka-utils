local utils = import './k8s_utils.libsonnet';
local argo = import 'github.com/jsonnet-libs/argo-cd-libsonnet/2.13/main.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';

local upstream = std.parseYaml(importstr 'github.com/argoproj/argo-cd/manifests/install.yaml');
local tanka_plugin = import './argocd_tanka_plugin/main.libsonnet';

local patched_argocd = function(namespace) utils.groupK8sDeep(
  [
    utils.withNamespace(o, namespace)
    for o in upstream
    if std.type(o) == 'object'
  ]
) + {
  // Install the argocd namespace
  Namespace+: {
    argocd: k.core.v1.namespace.new(name='argocd'),
  },
} + {
  // Install the argocd tanka plugin sidecar patch
  local plugin = tanka_plugin.new(namespace=namespace),
  Deployment+: {
    'argocd-repo-server'+: plugin.sidecar_patch,
  },
  ConfigMap+: {
    'argocd-cmp-server': plugin.cmp_plugin,
  },
};

{
  new(namespace):: patched_argocd(namespace),
  self_managed_root_app_set(
    namespace,
    repo_url,
    name='root',
    repo_path='.',
    default_namespace='root',
    target_revision='HEAD',
    env_path='./',
    project='default',
  ):: argo.argoproj.v1alpha1.applicationSet.new(name) {
    metadata+: {
      // ArgoCD detects resources only its own namespace at the root level
      namespace: namespace,
    },
    spec+: {
      generators: [{
        git: {
          repoURL: repo_url,
          revision: target_revision,
          files: [
            { path: std.stripChars(repo_path, '/') + '/' + std.stripChars(env_path, '/') + '/**/spec.json' },
          ],
        },
      }],
      goTemplate: true,
      template: {
        metadata: {
          name: '{{.path.basenameNormalized}}',
          // Remove annotations from template - will be handled by templatePatch
        },
        spec: {
          project: '{{if .spec.argocd.application.project}}{{.spec.argocd.application.project}}{{else}}"default"{{end}}',
          source: {
            repoURL: repo_url,
            targetRevision: target_revision,
            path: repo_path,
            plugin: {
              name: 'tanka',
              env: [
                {
                  name: 'TK_ENV',
                  value: '{{.metadata.name}}',
                },
              ],
            },
          },
          destination: {
            server: 'https://kubernetes.default.svc',
            // The namespace will only be set for namespace-scoped resources that have not set a value for .metadata.namespace
            namespace: default_namespace,
          },
          // Remove syncPolicy from template - will be handled by templatePatch
        },
      },
      // Move all non-string fields and complex templating to templatePatch
      templatePatch: |||
        metadata:
          annotations:
            argocd.argoproj.io/sync-wave: "{{if hasKey .spec.argocd.application "syncWave"}}{{printf "%v" .spec.argocd.application.syncWave}}{{else}}10{{end}}"
        spec:
          syncPolicy:
            automated:
              prune: {{if .spec.argocd.application.prune}}{{.spec.argocd.application.prune}}{{else}}true{{end}}
              selfHeal: {{if .spec.argocd.application.selfHeal}}{{.spec.argocd.application.selfHeal}}{{else}}true{{end}}
            syncOptions:
            {{- if .spec.argocd.application.syncOptions }}
            {{- range .spec.argocd.application.syncOptions }}
            - {{ . }}
            {{- end }}
            {{- else }}
            - CreateNamespace=true
            - ServerSideApply=true
            {{- end }}
      |||,
    },
  },
}
