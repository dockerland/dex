# dex

[![Build Status](https://travis-ci.org/dockerland/dex.svg?branch=master)](https://travis-ci.org/dockerland/dex)

Dex runs applications  _without_ installing them or their dependencies by
leveraging [docker](https://www.docker.com/). Dex also makes it [easier](docs/HOWTO.md#containerize-your-application) to contain and _properly_ execute
applications you write, no matter the OS.

Windowed/X11 applications are supported, so expect `dex run firefox` to work. [Pipes](https://en.wikipedia.org/wiki/Redirection_%28computing%29#Piping)
and [redirection](https://en.wikipedia.org/wiki/Redirection_%28computing%29) are
respected, so expect _pong_ from `echo 'ping' | docker run sed 's/ping/pong/'`.

Dex is plain [bash](https://www.gnu.org/software/bash/manual/bash.html). In fact
it's a _bashlication_ with a Makefile, modular design, and complete [bats](https://github.com/sstephenson/bats) testing. It can run
_anywhere docker works_, including Windows 10.

## installing dex

#### dependencies

Dex needs a working _bash shell_ and [docker](https://www.docker.com/) cli. Test
docker by opening your terminal and typing;
```sh
docker ps
[ $? -eq 0 ] && echo "Docker appears working. Lets install dex..."
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

At the heart, dex manages _'dexecutables'_ -- scripts that execute contained
applications under a [consistent runtime](docs/v1-runtime.md). The Dockerfiles
for these applications are kept in configurable [source repositories](#source-repositories) also
managed by dex.


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

Dex consults source repositories for the Dockerfile to build an image from --
similar to how yum and apt consult package sources. Thus,
__applications available to dex are dictated by source repository checkouts__.

Source Repositories are defined one-per-line in `$DEX_HOME/sources.list` as `<name> <url>`. URLs may point to the  _remote URL_ or _local path_ of a [git repository](https://git-scm.com/) with an `dex-images/` tree containing applications . Use `dex source add` to add additional sources. `dex help source` for more.

[sources.list example](sources.list) - [repository example](https://github.com/dockerland/dex-dockerfiles-core)

Checkouts are __only__ performed when a source is added. Use `dex source pull '*'` to downstream
changes to all defined sources, or `dex run --pull ...`  to downstream into the detected source.


### environmental variables

use variables to effect default dex behavior.

global envars | default | description
--- | --- | ---
DEX_API | v1 | api version
DEX_BIN_DIR | /usr/local/bin | dexecutable installation target directory
DEX_BIN_PREFIX | d | dexecutable installation prefix
DEX_HOME | ~/.dex | dex workspace, where checkouts and sources.list are kept.
DEX_NAMESPACE | dex/v1 | prefix used when tagging image builds
DEX_NETWORK| true | enables network fetching

v1 runtime vars | default | description
--- | --- | ---
DEX_DOCKER_CMD | | alternative command passed to docker run
DEX_DOCKER_ENTRYPOINT | |  alternative entrypoint passed to docker run
DEX_DOCKER_HOME | $DEX_HOME/homes/[image] | directory bind mounted as container's $HOME
DEX_DOCKER_WORKSPACE | $(pwd) |  directory bind mounted as container's CWD
DEX_DOCKER_GID| $(id -g) | gid to run the container under
DEX_DOCKER_UID| $(id -u) | uid to run the container under
DEX_DOCKER_LOG_DRIVER | none | logging driver to use for container
DEX_WINDOW_FLAGS | -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY | applied to windowed containers

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
