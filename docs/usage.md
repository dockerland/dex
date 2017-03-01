# dex Usage

At its heart, dex manages _'dexecutables'_ -- [runtime scripts](docs/v1-runtime.md) that execute
containerized applications. The Dockerfiles making up these applications
are managed in [source repositories](#source-repositories).

### source repositories

Dex consults source repositories for the Dockerfile to build application images from --
similar to how yum and apt consult package sources. Thus,
__applications available to dex are dictated by source repository checkouts__.

Source Repositories are defined one-per-line in `$DEX_HOME/sources.list` as `<name> <url>`. URLs may point to the  _remote URL_ or _local path_ of a [git repository](https://git-scm.com/). Each repository _must_ have a `dex-images/` tree containing images.

Use `dex repo` to manage source repositories. on.

[sources.list example](sources.list) - [repository example](https://github.com/dockerland/dex-dockerfiles-core)

> Repository checkouts are performed __once__ when a source is added.  Use `dex repo pull` to refresh checkout(s), or pass the `--pull` flag to run/ls/install/image commands to perform a checkout _on-the-fly_.

### environmental variables

You may override _default_ application runtime and dex command behavior by specifying environmental variables. [Learn about environmental variables](https://github.com/dockerland/charleston-containers/blob/master/docs/02-concepts.md#environmental-variables) if `export a=b` vs `a=b` is foreign.

#### dex command

variables effecting command behavior, e.g.

```sh
DEX_BIN_DIR=~/bin/ DEX_BIN_PREFIX=acme- dex install ag
# ^^^ ag installed to ~/bin/acme-ag
```

var | default | description
--- | --- | ---
DEX_BIN_DIR | $DEX_HOME/bin | dexecutable installation target directory
DEX_BIN_PREFIX | d | dexecutable installation prefix
DEX_HOME | ~/.dex | dex workspace, where checkouts and sources.list are kept.
DEX_NAMESPACE | dex/v1 | prefix used when tagging image builds
DEX_NETWORK| true | enables network fetching
DEX_RUNTIME | v1 | runtime api version


#### dex runtime

variables effecting runtime behavior, e.g.

```sh
dex install --global ansible
DEX_DOCKER_ENTYPOINT=bash ansible
# ...we're now in the ansible container's bash shell...
```


v1 runtime vars | default | description
--- | --- | ---
DEX_DOCKER_CMD | _image_  | alternative command passed to docker run
DEX_DOCKER_ENTRYPOINT | _image_  |  alternative entrypoint passed to docker run
DEX_DOCKER_HOME | _image_  | host directory bind mounted as container's `$HOME`. Typically applications get their own home (`$DEX_HOME/homes/[image]-[tag]`) to avoid clobbering system-installed versions.
DEX_DOCKER_WORKSPACE | current pwd |  host directory bind mounted as container's CWD
DEX_DOCKER_GID| current uid | host gid to run the container under
DEX_DOCKER_UID| current gid | host uid to run the container under
DEX_DOCKER_LOG_DRIVER | none | logging driver to use for container
DEX_WINDOW_FLAGS | _runtime_ | applied to windowed containers, typically `-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY`



## use cases

TODO

#### as a bootstrap

#### as a dependency manager

#### wrapping an environment
