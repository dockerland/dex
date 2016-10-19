# dex

[![Build Status](https://travis-ci.org/dockerland/dex.svg?branch=master)](https://travis-ci.org/dockerland/dex)

Dex runs applications _without_ the need to install them or their dependencies by leveraging [docker](https://www.docker.com/). Dex also makes it [easier](docs/HOWTO.md#containerize-your-application) to containerize and _consistently_ execute
applications, no matter the OS.

Windowed/X11 applications are supported, so expect `dex run firefox`. [Pipes](https://en.wikipedia.org/wiki/Redirection_%28computing%29#Piping)
and [redirection](https://en.wikipedia.org/wiki/Redirection_%28computing%29) behave, so expect _pong_ from `echo 'ping' | docker run sed 's/ping/pong/'`.

Dex is plain [bash](https://www.gnu.org/software/bash/manual/bash.html). In fact
it's a _bashlication_ with a Makefile, modular design, and complete [bats](https://github.com/sstephenson/bats) testing. It can run
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
./dex.sh
# -or- install to /usr/local/bin/dex
sudo make install
```

## using dex

At its heart, dex manages _'dexecutables'_ -- [runtime scripts](docs/v1-runtime.md) that execute
containerized applications. The Dockerfiles making up these applications
are managed in [source repositories](#source-repositories).


### quickstart

```sh
# get help
dex help

# run 'debian' from any repository
#  (first image matching 'debian' is built & executed)
dex run debian

# run 'ag' (the grep replacement!) from the "extra" repository
dex run extra/ag

# play sed pong
echo 'ping' | dex run sed 's/ping/pong/'

# install gitk (defaults to /usr/local/bin/dgitk) and execute it
#  (gitk is a windowed application and requires e.g. X)
sudo dex install gitk && dgitk

# add a local source repository named "dev" and install all images from it
dex source add dev /path/to/my-dex-repo
dex install 'dev/*'

# install macos-sed to an alternative path, without the 'd' prefix
export PATH=~/bin/macos:$PATH
(
  export DEX_BIN_DIR=~/bin/macos/
  dex install --global sed:macos
)
sed
# ^^^ yay 1993

# use DOS like a boss
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

Source Repositories are defined one-per-line in `$DEX_HOME/sources.list` as `<name> <url>`. URLs may point to the  _remote URL_ or _local path_ of a [git repository](https://git-scm.com/) with a `dex-images/` tree containing applications. Use `dex source add` to add additional sources, and `dex help source` for additional information.

[sources.list example](sources.list) - [repository example](https://github.com/dockerland/dex-dockerfiles-core)

Repository checkouts are performed __once__ when a source is added. Checkouts go to `~/.dex/checkouts/` by default. Use `dex source pull '*'` to checkout the latest from all sources, or `dex run --pull ...` to checkout on-the-fly when running an application.


### environmental variables

#### dex command

variables that globally effect the dex command, e.g.

```sh
DEX_BIN_DIR=~/bin/ DEX_BIN_PREFIX=acme- dex install ag
# ^^^ ag installed to ~/bin/acme-ag
```

var | default | description
--- | --- | ---
DEX_BIN_DIR | /usr/local/bin | dexecutable installation target directory
DEX_BIN_PREFIX | d | dexecutable installation prefix
DEX_HOME | ~/.dex | dex workspace, where checkouts and sources.list are kept.
DEX_NAMESPACE | dex/v1 | prefix used when tagging image builds
DEX_NETWORK| true | enables network fetching
DEX_RUNTIME | v1 | runtime api version


#### dex runtime

variables that effect dex execution, e.g.

```sh
dex install ansible
DEX_DOCKER_ENTYPOINT=bash dansible
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

**work in progress** see [docs/HOWTO.md](docs/HOWTO.md#containerize-your-application)

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
