
# Realm Deployment Stack

This repository contains a Helm chart for deploying game-related resources into a single namespace.

The intent is for this chart to be fully managed by ArgoCD, deploying into namespaces like `realm-dev`/`realm-stage`/`realm` depending on the branch.

The major components are:
- `templates/paper`: contains manifests for deploying the Runic Realms Agones game fleet of Paper servers
- `templates/velocity`: contains manifests for deploying a Velagones-Managed Velocity Proxy
- `templates/trove`: contains manifests for deploying a ScyllaDB instance and our custom wrapper around it,  [Trove](https://github.com/runic-studios/trove)

## Configuring Our Servers

Note that there are two types of configuration files (i.e. plugin YAMLs, server configs, etc) that may be modified:
1) Global configuration: Things like velocity settings, certain external plugin settings, and things that don't change based on the environment
2) Environment-specific configuration: Things like game plugin settings, resource limits, and things that change in each environment

Global configuration can go in two locations (that are used for different purposes):
- `Realm-Paper-Base`/`Realm-Velocity-Base` repos:
  - These should be modified very infrequently (only between major MC version updates, not game updates)
  - These are pushed to a shared PV that is mounted on every instance, then copied into their local file system
- `config/base` in this repository:
  - These can be modified for different game releases

Additionally, you can configure environment-specific configuration in this repo through `config/env/XXX`.

Both the `config/base` and `config/env` folders are templated each into a single ConfigMap, then mounted on the pods.

All of these different layers are merged with [Palimpsest](https://github.com/Runic-Studios/Palimpsest), our in-house tool for merging configuration.
- The order of merging (from lowest to highest) is the `Realm-XXX-Base` repository, then `config/base`, then `config/env/XXX`.
- Palimpsest is capable of merging configuration files themselves, so that keys in higher-priority sources overwrite those that come from lower-priority sources.

## More Modifications?
- Looking to modify the image we build for velocity/paper servers? Check [Realm-Paper](https://github.com/runic-studios/Realm-Paper) and [Realm-Velocity](https://github.com/runic-studios/Realm-Velocity)
  - These both contain `artifact-manifest.yaml` files that specify where to pull artifacts from, which have git-ops updated version tags (for internal projects, like RR-Game/Palimpsest/Velagones)
- Looking to modify base configuration? Check [Realm-Paper-Base](https://github.com/runic-studios/Realm-Paper) and [Realm-Velocity-Base](https://github.com/runic-studios/Realm-Velocity)
   - These contain the bare-bones set of files required to run a Velocity/Paper server, like server jars, libraries, static configuration, etc
- Looking to modify resource limits? This is in this repository.
  - `values.yml` has some templated resource limits that can be overwritten by the env-specific `XXX-values.yaml` files.
  - JVM memory limits are also passed through here (via env-var into the pod)
- Looking to modify Kubernetes resources that aren't game related (ArgoCD, ARC, Harbor, Reposilite, Agones, Etc)? Check [Deploy](https://github.com/runic-studios/Deploy).
  - This repository contains a static Kustomization stack for deploying everything in the cluster.
