# tanka-utils
Jsonnet library for use with Grafana Tanka

## ArgoCD and Tanka Integration

The `tanka-utils` project provides pre-configured settings to seamlessly integrate ArgoCD with Tanka by establishing a custom Tanka plugin for ArgoCD. This integration is facilitated through a Config Management Plugin (CMP) that enables ArgoCD to utilize Tanka for manifest generation.

### How the Tanka Plugin is Set Up

1.  **ConfigMap for the Plugin Configuration (`argocd_tanka_plugin/configmap_plugin.libsonnet`):**
    This file defines a `ConfigManagementPlugin` manifest which specifies the initialization and generation commands for Tanka. This manifest is stored in a ConfigMap, which is then mounted into the plugin's sidecar container. The `generate` command utilizes `tk show --dangerous-allow-redirect --tla-code bootstrap=false`. The `bootstrap` argument is a top-level argument that can be used to control the inclusion of bootstrap manifests.

2.  **Sidecar Container to the ArgoCD Repo Server (`argocd_tanka_plugin/sidecar_patch.libsonnet`):**
    This library patches the `argocd-repo-server` deployment to include a sidecar container that runs the Tanka plugin. This sidecar container executes the `argocd-cmp-server` and mounts necessary volumes, including the plugin configuration from the ConfigMap.

3.  **Configuring ArgoCD Applications to Use the Tanka Plugin:**
    When defining an ArgoCD `Application` (for example, using `self_managed_root_app_set` from `argocd_itself.libsonnet`), you specify the plugin and set environment variables. For instance, the `TANKA_PATH` environment variable specifies the path to the Tanka environment within the repository.

    **Example `Application` configuration snippet:**
    ```yaml
    spec:
      source:
        repoURL: [your project repo URL]
        path: [path to your Tanka project]
        targetRevision: HEAD
        plugin:
          name: tanka # Name of the CMP plugin
          env:
          - name: TANKA_PATH
            value: environments/prod # Example path to your Tanka environment
    ```

## `argocd_itself.libsonnet`

This library provides functions for deploying and managing ArgoCD within your Tanka environments.

### `new(namespace)`

This function is used to generate the core ArgoCD manifests, applying them to the specified Kubernetes namespace. It also includes patches for a Tanka plugin sidecar.

**Usage Example:**

```jsonnet
local argocd_itself = import 'argocd_root.libsonnet';

{
  argocd_itself: argocd_itself.new(namespace='argocd'),
}
```

### `self_managed_root_app_set(namespace, repo_url, name='root', repo_path='.', default_namespace='root', target_revision='HEAD', env_path='./', project='default')`

This function creates an ArgoCD ApplicationSet resource, which is responsible for managing multiple ArgoCD applications. It defines a "root" ApplicationSet that discovers and syncs applications within your Git repository.

**Parameters:**

*   `namespace`: The Kubernetes namespace where the ApplicationSet will be deployed. (e.g., `'argocd'`)
*   `repo_url`: The URL of the Git repository containing your application manifests. (e.g., `'https://github.com/your-org/your-repo.git'`)
*   `name`: (Optional) The name of the ApplicationSet. Defaults to `'root'`.
*   `repo_path`: (Optional) The base path within the Git repository where the ApplicationSet will look for application definitions. Defaults to `'.'`.
*   `default_namespace`: (Optional) The default namespace for applications discovered by this ApplicationSet. Defaults to `'root'`.
*   `target_revision`: (Optional) The target Git revision (branch, tag, or commit hash) to sync from. Defaults to `'HEAD'`.
*   `env_path`: (Optional) A path within the `repo_path` that helps locate environment-specific `spec.json` files for application discovery. (e.g., `'environments/prod'`)
*   `project`: (Optional) The ArgoCD project to associate with the applications created by this ApplicationSet. Defaults to `'default'`.

**Usage Example:**

```jsonnet
local argocd_itself = import 'argocd_root.libsonnet';

{
  root_app_set: argocd_itself.self_managed_root_app_set(
    namespace='argocd',
    default_namespace='root',
    repo_url='https://gitlab.com/jaideep12/temp.git',
    env_path='environments/prod',
    repo_path='.',
    target_revision='HEAD',
  ),
}
```
