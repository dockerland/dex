# dex

[![Join the chat at https://gitter.im/dockerland/dex](https://badges.gitter.im/dockerland/dex.svg)](https://gitter.im/dockerland/dex?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) | [![Build Status](https://travis-ci.org/dockerland/dex.svg?branch=master)](https://travis-ci.org/dockerland/dex)


* dex allows you to run applications _without_ installing them or their dependencies.
  * dex is a [docker](http://www.docker.com) package manager for applications and tooling (like `git`, `ffmpeg`, and `javac`) as well as daemons (like `redis`, `selenium`, and `caddy`).


* dex is like [whalebrew](https://github.com/bfirsh/whalebrew), except in bash for extra pain.
  * dex images are built from regular Dockerfiles, and use labels to specify runtime behavior. If your app is dockerized, it can be dexified in seconds.


### quickstart

#### install dex

```sh
curl -L http://get.iceburg.net/dex/latest-0.12.x/dex > /usr/local/bin/dex && \
chmod +x /usr/local/bin/dex
```

##### list available images
```sh
dex ls
```

##### play sed pong
```sh
echo 'ping' | dex run sed 's/ping/pong/'
# ^^^ sed from the 'sed' container, not your host machine!
```

##### run 'ag' (the grep replacement!) from the "extra" repository
```sh
echo "hello" > world.txt
dex run extra/ag "hello"
```

##### WTF is dex doing?
```sh
DEX_DEBUG=true dex run extra/ag "hello"
```

##### bind mount a host path by passing arbitrary volume flag
```sh
$ mkdir -p /tmp/ping/pong
$ DEX_DOCKER_FLAGS="-v /tmp/ping:/tmp/ping" ./main.sh run debian ls /tmp/ping
pong
```

see [v1-runtime docs](docs/v1-runtime.md#runtime-variables) for more runtime variables.

##### use DOS like a boss
```sh
mkdir dos-test
cd dos-test
dex run edit enjoy-edit.com.txt
cd ..
dex run deltree dost-test
# ^^^ yay 1984
```

##### install macos-sed to /usr/local/bin, with a'macos-' prefix
```sh
DEX_BIN_DIR=/usr/local/bin DEX_BIN_PREFIX=macos- dex install sed:macos
macos-sed --help
# ^^^ yay 1994
```

##### register your custom repository and install all images from it
```sh
dex repo add acme-tools git@github.com/acme-tools/bootstrap.git
dex install acme-tools/
# ^^^ super useful in bootstrap scripts
```

[docs/usage.md](docs/usage.md) for more.

## requirements

dex can run _anywhere docker works_, including Windows 10.

  * [docker](https://www.docker.com/)
  * [git](https://git-scm.com/)
  * [bash](https://www.gnu.org/software/bash/)

## installation
Use one of the below methods to install dex.

#### from a release

dex is periodically packaged as a monolithic script and published to;
  * [get.iceburg.net](http://get.iceburg.net)
  * [github](https://github.com/briceburg/shell-helpers/releases)


download a release and copy it to a folder in your $PATH;

```sh
curl -L http://get.iceburg.net/dex/latest-0.12.x/dex > /usr/local/bin/dex && \
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

#### from a series of tubes (no installation)
Diehards run dex from the Al Gore provided Cloud
```sh
curl -L http://get.iceburg.net/dex/latest-0.12.x/dex | bash -s 'install' 'ag'
# ^^^ installs 'ag' without installing dex
```

## contribute to dex

By all means! Before you submit a PR, please include tests and make sure
they pass. See [tests](tests/) for more.

### containerize your application

The process is the same as providing a normal Dockerfile, except you use [label(s)](docs/v1-runtime.md#runtime-labels) to effect runtime behavior.


> Others may find your image useful! **Please** publish to one of our [repositories](https://github.com/dockerland).
  * [core](https://github.com/dockerland/dex-dockerfiles-core)
  * [extra](https://github.com/dockerland/dex-dockerfiles-extra)

Use existing Dockerfiles in the above repositories as reference, or see [docs/HOWTO.md](docs/HOWTO.md#containerize-your-application) for more details.


## why dex?

Dex provides consistency and convenience around the _installation_ and _execution_ of application containers, and we we wrote it as part of a "modern" bootstrap to _improve tooling management_.

#### dex is safe

Dex applications are **independent**, **portable**, and **non-intrusive**. Gone are the days of mucking up a developer's machine and fiddling with versions. You no longer need `java`, `node`, `ruby`, `python`, or even `make` locally installed to be productive.

#### dex is easy

Dex remains consistent with docker command line behavior. Users and tool authors can containerize, distribute, and _consistently_ execute applications as _intended_.

#### dex is fun

We also wanted to try fun things like executing MacOS commands to test flag behavior or seeing if we could use edit.com from DOS (hint: it [works!](https://github.com/dockerland/dex-dockerfiles-extra/tree/master/dex-images/edit)). We also want to support windowed/X11 applications, so expect `dex run firefox`.

See other [use cases](docs/usage.md#use-cases) for ideas on leveraging dex.

## license

Dex is licensed under the Apache License, Version 2.0.
See [LICENSE](LICENSE) for the full license text.
