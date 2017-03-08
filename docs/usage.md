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

See [v1 runtime variables](v1-runtime.md#runtime-variables) for a complete list.


## use cases

WIP

#### as a bootstrap

see [dex and a "modern" bootstrap](https://github.com/dockerland/charleston-containers/tree/master/talks/20170301_Dex-and-a-modern-Bootstrap)




#### as a dependency manager

#### wrapping an environment
