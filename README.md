# dex

[![Build Status](https://travis-ci.org/dockerland/dex.svg?branch=master)](https://travis-ci.org/dockerland/dex)

Dex makes it easy to run applications _without_ the need to install them or
their dependencies by leveraging [docker](https://www.docker.com/) containers.

It also makes it [easy-peasy](docs/HOWTO.md#containerize-your-application) for tool authors to containerize, distribute, and
execute applications in a _consistent_ and _intentional_ way.

We provide conveniences around utility _installation_ and
_execution_ -- think `git` and `npm` as opposed to long-running daemons like
`httpd` and `crond` -- and wrote dex to improve our tooling [bootstrap](). It is now;
  * non intrusive
    * does not conflict with [**or depend upon**] system installed commands
    * our developers literally need nothing. not even git, python, or java.
  * and super easy to update and install.
    ```
    dex install --pulll acme-tools/
    ```

Windowed/X11 applications are supported, so expect `dex run firefox`. [Pipes](https://en.wikipedia.org/wiki/Redirection_%28computing%29#Piping)
and [redirection](https://en.wikipedia.org/wiki/Redirection_%28computing%29) behave, so expect _pong_ from `echo 'ping' | docker run sed 's/ping/pong/'`.

Dex is plain [bash](https://www.gnu.org/software/bash/manual/bash.html). It's actually a  _bashlication_ with a Makefile, modular design, and complete [bats](https://github.com/sstephenson/bats) testing. It can run
_anywhere docker works_, including Windows 10.

## installing dex

#### dependencies

Dex needs [docker](https://www.docker.com/) and [git](https://git-scm.com/). Test
docker in your terminal via;
```sh
docker info && echo "Docker appears working. Lets install dex..."
```

### from a github release

* download a [release](https://github.com/dockerland/dex/releases/) and copy it to a folder in your $PATH

### from source

```sh
git clone git@github.com:dockerland/dex.git
cd dex
# run dex,
./main.sh
# -or- install to /usr/local/bin/dex
sudo make install
```

## using dex

At its heart, dex manages _'dexecutables'_ -- [runtime scripts](docs/v1-runtime.md) that execute
containerized applications. The Dockerfiles making up these applications
are managed in [source repositories](#source-repositories).


### quickstart

##### run 'ag' (the grep replacement!) from the "extra" repository
```sh
echo "hello" > world.txt
dex run extra/ag "hello"
```

##### play sed pong
```sh
echo 'ping' | dex run sed 's/ping/pong/'
```

##### add a custom source repository and install all images from it
```sh
dex repo add acme-tools git@github.com/acme-tools/dex.git
dex install acme-tools/
```

##### install macos-sed to an alternative path, without the 'd' prefix
```sh
DEX_BIN_DIR=/usr/local/bin sudo dex install --global sed:macos
sed --help
# ^^^ yay 1993
```

##### use DOS like a boss
```sh
export PATH="~/.dex/bin:$PATH"
dex install --global deltree
mkdir -p /tmp/dex-makes-it/possible
deltree /tmp/dex-makes-it
# ^^^ yay 1983
```


[docs/HOWTO.md](docs/HOWTO.md) for more.

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

## developing dex

### containerize your application

The process is no different than providing a normal Dockerfile including your application and it's dependencies. If you have already containerized your application, all you need to do is add dex specific [label(s)](https://docs.docker.com/engine/reference/builder/#/label).

See [docs/HOWTO.md](docs/HOWTO.md#containerize-your-application) for details


### contributing to dex

By all means! Before you submit a PR, please include tests and make sure
they pass. See [tests](tests/) for more.

### license

Dex is licensed under the Apache License, Version 2.0.
See [LICENSE](LICENSE) for the full license text.

## why dex?

* _docker_ and _dex_ are now your only dependencies - your OS is a clean OS.
* makes it easier to containerize and _properly_ execute any application from any OS.
  * dependency isolation - different versions of python? no problem
* test tools from other platforms - `dex install sed:macos && dsed --help`
