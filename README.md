# dex

[![Join the chat at https://gitter.im/dockerland/dex](https://badges.gitter.im/dockerland/dex.svg)](https://gitter.im/dockerland/dex?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) | [![Build Status](https://travis-ci.org/dockerland/dex.svg?branch=master)](https://travis-ci.org/dockerland/dex)

With dex you can run applications _without_ installing them or their dependencies --
think about it as [docker](http) for `git` and `npm` as opposed to `httpd` and `crond`.


## why dex?

We want to provide convenience around _installation_ and
_execution_ of application containers, and wrote dex to improve tooling management in our [bootstrap]().

Our developers now literally need nothing other than _docker_, _git_, and _bash_ -- not even python or java.

#### make it safe

Dex applications are **independent** and **non-intrusive**.
  * do not depend upon system installed commands or libraries
  * do not muck up the OS or collide with existing settings

#### make it easy

Dex makes it easy for users and tool authors to containerize, distribute, and _consistently_ execute applications as _intended_.

  * remain consistent with docker behavior
  * single-command to _update_ and _install_ tools.


#### make it fun

We also wanted to try fun things like executing MacOS commands to test flag behavior or seeing if we could use [edit](https://github.com/dockerland/dex-dockerfiles-extra/tree/master/dex-images/edit) from DOS.
  * different versions of python? no problem.
  * git [source repositories](docs/usage.md#source-repositories) let you roll your own


Windowed/X11 applications are supported, so expect `dex run firefox`. [Pipes](https://en.wikipedia.org/wiki/Redirection_%28computing%29#Piping)
and [redirection](https://en.wikipedia.org/wiki/Redirection_%28computing%29) behave, so expect _pong_ from `echo 'ping' | docker run sed 's/ping/pong/'`.

## run dex

#### requirements
Dex is plain [bash](https://www.gnu.org/software/bash/manual/bash.html). It's actually a  _bashlication_ with a Makefile, modular design, and complete [bats](https://github.com/sstephenson/bats) testing. It can run
_anywhere docker works_, including Windows 10.

  * [docker](https://www.docker.com/)
  * [git](https://git-scm.com/)
  * [bash](https://www.gnu.org/software/bash/)


### installation

dex is periodically packaged as a monolithic script and published to;
  * [get.iceburg.net](http://get.iceburg.net)
  * [github](https://github.com/briceburg/shell-helpers/releases)


#### from a release

* download a [release](https://github.com/dockerland/dex/releases/) and copy it to a folder in your $PATH

```sh
curl -L http://get.iceburg.net/dex/latest-v1/dex > /usr/local/bin/dex && \
chmod +x /usr/local/bin/dex
```

#### from source

```sh
git clone git@github.com:dockerland/dex.git
cd dex
# run dex,
./main.sh
# -or- install to /usr/local/bin/dex
sudo make install
```

#### from a series of tubes
Diehards run dex from the Al Gore provided Cloud
```sh
# install 'ag' via a series of tubes
curl -L http://get.iceburg.net/dex/latest-v1/dex | bash -s 'install' 'ag'
```

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

[docs/usage.md](docs/usage.md) for more.

## developing dex

### containerize your application

The process is no different than providing a normal Dockerfile including your application and it's dependencies. If you have already containerized your application, all you need to do is add dex specific [label(s)](https://docs.docker.com/engine/reference/builder/#/label).

See [docs/HOWTO.md](docs/HOWTO.md#containerize-your-application) for details


### contributing to dex

By all means! Before you submit a PR, please include tests and make sure
they pass. See [tests](tests/) for more.

## license

Dex is licensed under the Apache License, Version 2.0.
See [LICENSE](LICENSE) for the full license text.
