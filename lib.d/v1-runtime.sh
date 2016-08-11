#!/usr/bin/env bash

# runtime defaults,
#  images may provide a org.dockerland.dex.<var> label supplying a value
#  that overrides these default values.

__home=~
__workspace=$(pwd)
__docker_flags="-i"
__docker_entypoint=
__docker_cmd=

# You may override these by exporting the following vars:
#
# DEX_HOME - directory that will be mounted to the container's $HOME
# DEX_WORKSPACE - directory that be mounted to the container's $WORKSPACE (cwd)
# DEX_DOCKER_FLAGS - flags passed to docker run
# DEX_DOCKER_ENTRYPOINT - alternative entrypoint passed to docker run
# DEX_DOCKER_CMD - alternative command passed to docker run
#
# DEX_X11_FLAGS - typically appended to _DEX_DOCKER_FLAGS in the .env file of
#                S images providing X11 applications

DEX_X11_FLAGS=${DEX_X11_FLAGS:-"-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY"}

v1-runtime(){
  [ -z "$__image" ] && echo "missing runtime image" && exit 1

  # augment defaults with image meta
  local prefix="org.dockerland.dex"
  for label in home workspace docker_flags docker_entrypoint docker_cmd; do
    # @TODO reduce this to a single docker inspect command
    val=$(docker inspect --format "{{ index .Config.Labels \"$prefix.$label\" }}" $__image)
    [ -z "$val" ] && continue
    eval "__$label=$val"
  done

  DEX_HOME=${DEX_HOME:-$__home}
  DEX_WORKSPACE=${DEX_HOME:-$__workspace}
  DEX_DOCKER_FLAGS=${DEX_DOCKER_FLAGS:-$__docker_flags}
  DEX_DOCKER_ENTRYPOINT=${DEX_DOCKER_ENTRYPOINT:-$__docker_entypoint}
  DEX_DOCKER_CMD=${DEX_DOCKER_CMD:-$__docker_cmd}

  #@TODO implement piping & redirection detection

  [ -z "$DEX_DOCKER_ENTRYPOINT"] && \
    DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS --entrypoint=$DEX_DOCKER_ENTRYPOINT"

  docker run $DEX_DOCKER_FLAGS \
    -v $DEX_HOME:/dex/home \
    -v $DEX_WORKSPACE:/dex/workspace \
    -e HOME=/dex/home \
    --rm --workdir=/dex/workspace -u $(id -u):$(id -g) \
    $__image $DEX_DOCKER_CMD

  return $?
}
