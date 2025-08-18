// This is the main libsonnet file for the argocd tanka plugin

local tanka_cmp_plugin = import './configmap_plugin.libsonnet';
local sidecar_patch = import './sidecar_patch.libsonnet';

{
  new(namespace='argocd', tk_version='v0.33.0', jb_version='v0.6.0', plugin_name='cmp-tanka'):: {
    sidecar_patch: sidecar_patch.new(tk_version=tk_version, jb_version=jb_version, plugin_name=plugin_name),
    cmp_plugin: tanka_cmp_plugin.new(name=plugin_name, namespace=namespace),
  },
}
