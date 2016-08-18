# dex

[![Build Status](https://travis-ci.org/dockerland/dex.svg?branch=master)](https://travis-ci.org/dockerland/dex)

Dex runs applications  _without_ installing them or their dependencies -- by
using [docker](https://www.docker.com/) containers.

GUI applications are supported through X11, so expect `dex run firefox` and
`dex run gitk` to work. [Piping](https://en.wikipedia.org/wiki/Redirection_%28computing%29#Piping)
and [redirection](https://en.wikipedia.org/wiki/Redirection_%28computing%29) are
respected, so expect _pong_ from `echo 'ping' | docker run sed 's/ping/pong/'`.

Dex is plain [bash](https://www.gnu.org/software/bash/manual/bash.html). In fact
it's a _bashlication_ with a Makefile, modular design, and complete [bats](https://github.com/sstephenson/bats) testing. It should be able to run
_anywhere docker works_ including [Windows 10](https://msdn.microsoft.com/en-us/commandline/wsl/about).


## using dex

At the heart, dex manages _'dexecutables'_. These are  scripts that execute docker containers under a consistent _'api runtime'_. The Dockerfiles
for these containers are kept in configurable _'source repositories'_ also
managed by dex.


### quickstart

```sh
# get help
dex help

# run 'debian' from the 'core' repository
dex run core/debian

# test piping to 'sed'
echo 'ping' | docker run sed 's/ping/pong/'

# install gitk  (as /usr/local/bin/dgitk)
sudo dex install gitk
dgitk
# ^^^ launches gitk:latest

# install all images from the core/ repository, pulling any changes first.
sudo dex install --pull "core/*"

# install macos-sed to an alternative path, without the 'd' prefix
export DEX_BIN_DIR=~/bin/macos/
export PATH=~/bin/macos:$PATH
dex install --global sed:macos
sed
# ^^^ launches sed:macos
```

### source repositories

Dex consults source repositories for the Dockerfile to build an image from --
similar to how yum and apt consult package sources. These are defined in
`$DEX_HOME/sources.list` and represent regular [git repositories](https://git-scm.com/)
with an `images/` tree. Thus, __applications available to dex
are dictated by source repository checkouts__.

Checkouts of source repositories are performed when added. Use `dex source pull '*'` to pull upstream changes into all defined sources, or the _--pull_ flag -- e.g. `dex run --pull firefox` to update the source(s) before running.

Dex defines two source repositories; _'core'_ and _'extra'_.
Use `dex source add` to add additional sources. Sources may point to _remote_ URLs
or _local_ paths of a git repository. `dex help source` for more.


### environmental variables

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
DEX_DOCKER_HOME | ~ | directory bind mounted as container's $HOME
DEX_DOCKER_WORKSPACE | $(pwd) |  directory bind mounted as container's CWD
DEX_DOCKER_FLAGS | | additional flags passed to docker run
DEX_DOCKER_ENTRYPOINT | |  alternative entrypoint passed to docker run
DEX_DOCKER_CMD | | alternative command passed to docker run
DEX_DOCKER_UID| $(id -u) | uid to run the container under
DEX_DOCKER_GID| $(id -g) | gid to run the container under
DEX_DOCKER_LOG_DRIVER | none | logging driver to use for container
DEX_DOCKER_PERSIST | false | when false, container is removed after it exits

in addition, we define
```
# use DEX_X11_FLAGS to overwride flags passed by X11 images.
DEX_X11_FLAGS="-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY"
```

## developing dexecutables

* TBD
  * labeling / api versioning
  * X11 examples
  * tagging conventions
  * org.dockerland.dex.docker_home labels, non absolute path relative to $DEX_HOME/<api>-homes/<label>


## installing dex

#### dependencies

The only dependency of dex is a working bash shell and a working [docker](https://www.docker.com/) cli. Test
that docker is working by opening your terminal and typing
```sh
docker ps
[ $? -eq 0 ] && echo "Docker appears working. Lets install dex..."
```

### from a github release

* download a [release](https://github.com/dockerland/dex/releases/) and copy it to a folder in your $PATH

### from source

```
git clone git@github.com:dockerland/dex.git
cd dex
make
sudo make install
```

alternatively, run `./dex.sh` from the source checkout.


## license

Dex is licensed under the Apache License, Version 2.0.
See [LICENSE](LICENSE) for the full license text.

## why dex?

* _docker_ and _dex_ are now your only dependencies - your OS is a clean OS.
* dependency isolation - different versions of python? no problem
* test tools from other platforms - `dex install sed:macos && dsed --help`
