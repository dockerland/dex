#!/usr/bin/env bash

# runtime defaults,
#  images may provide a .env file supplying a set of differnt defaults
#  export without underscore prefix before running image to override
#
# DEX_HOME - directory that will be mounted to the container's $HOME
# DEX_WORKSPACE - directory that be mounted to the container's $WORKSPACE (cwd)
# DEX_DOCKER_FLAGS - flags passed to docker run
# DEX_DOCKER_ENTRYPOINT - alternative entrypoint passed to docker run
# DEX_DOCKER_CMD - alternative command passed to docker run
#
# DEX_X11_FLAGS - typically appended to _DEX_DOCKER_FLAGS in the .env file of
#                S images providing X11 applications

_DEX_HOME=~
_DEX_WORKSPACE=$(pwd)
_DEX_DOCKER_FLAGS="-i"
_DEX_DOCKER_ENTRYPOINT=
_DEX_DOCKER_CMD=


_DEX_X11_FLAGS="-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY"

dex-run-image(){

   source base64 decoded env

   inspect ENV for API_VERSION

   DEX_RUNTIME_A






}
