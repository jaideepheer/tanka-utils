// This is the sidecar patch that will be used to run the tanka plugin
// Apply this patch to the sidecar container of the argocd-repo-server deployment

local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.29/main.libsonnet';

{
  new(tk_version='v0.33.0', jb_version='v0.6.0', plugin_name='cmp-tanka', helm_version='v3.18.5')::
    {
      spec+: {
        template+: {
          spec+: {
            // Add the required volumes that don't exist by default
            volumes+: [
              // Plugin-specific volumes
              {
                name: plugin_name,
                configMap: {
                  name: plugin_name,
                },
              },
            ],
            containers+: [
              // Sidecar for tanka plugin
              {
                name: 'cmp',
                image: 'curlimages/curl:latest',
                command: [
                  'sh',
                  '-c',
                  |||
                    cd /home/argocd/cmp-server/plugins && \
                    curl -Lo jb "https://github.com/jsonnet-bundler/jsonnet-bundler/releases/download/%s/jb-linux-amd64" && \
                    curl -Lo tk "https://github.com/grafana/tanka/releases/download/%s/tk-linux-amd64" && \
                    curl -Lo helm.tar.gz "https://get.helm.sh/helm-%s-linux-amd64.tar.gz" && \
                    tar -zxf helm.tar.gz && \
                    mv linux-amd64/helm ./helm && \
                    rm -rf helm.tar.gz linux-amd64 && \
                    chmod +x jb tk helm && \
                    TANKA_HELM_PATH=/home/argocd/cmp-server/plugins/helm /var/run/argocd/argocd-cmp-server
                  ||| % [jb_version, tk_version, helm_version],
                ],
                securityContext: {
                  runAsNonRoot: true,
                  runAsUser: 999,
                },
                volumeMounts: [
                  {
                    mountPath: '/var/run/argocd',
                    name: 'var-files',
                  },
                  {
                    mountPath: '/home/argocd/cmp-server/plugins',
                    name: 'plugins',
                  },
                  {
                    mountPath: '/home/argocd/cmp-server/config/plugin.yaml',
                    subPath: 'plugin.yaml',
                    name: plugin_name,
                  },
                ],
              },
            ],
          },
        },
      },
    },
}
