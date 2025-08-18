// local std = import 'std/jsonnet';

{
  new(name='cmp-tanka', namespace='argocd'):: {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      name: name,
      namespace: namespace,
    },
    data: {
      'plugin.yaml': std.manifestYamlDoc({
        apiVersion: 'argoproj.io/v1alpha1',
        kind: 'ConfigManagementPlugin',
        metadata: { name: 'tanka' },
        spec: {
          // This version is appended to the plugin name requiring apps to use the full name with version
          // We don't need version for now
          // version: cmp_version,
          init: {
            command: [
              'sh',
              '-c',
              '/home/argocd/cmp-server/plugins/jb install',
            ],
          },
          generate: {
            command: [
              'sh',
              '-c',
              'TANKA_HELM_PATH=/home/argocd/cmp-server/plugins/helm /home/argocd/cmp-server/plugins/tk show ${ARGOCD_ENV_TK_ENV} --dangerous-allow-redirect --tla-code bootstrap=false',
            ],
          },
          // We don't need to discover the jsonnet files, we'll use the app's config to tell us the exact folder and repo to use
          // discover: { fileName: './environments/*/main.jsonnet' },
        },
      }),
    },
  },
}
