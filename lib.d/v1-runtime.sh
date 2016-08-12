#!/usr/bin/env bash

# runtime defaults,
#  images may provide a org.dockerland.dex.<var> label supplying a value
#  that overrides these default values, examples are:
#  org.dockerland.dex.host_home
#  org.dockerland.dex.host_workspace
#  org.dockerland.dex.docker_flags

__host_home=~
__host_workspace=$(pwd)
__docker_flags=
__docker_entypoint=
__docker_cmd=

# You may override these by exporting the following vars:
#
# DEX_HOST_HOME - directory that will be mounted to the container's $HOME
# DEX_HOST_WORKSPACE - directory that be mounted as container's CWD
# DEX_DOCKER_FLAGS - flags passed to docker run
# DEX_DOCKER_ENTRYPOINT - alternative entrypoint passed to docker run
# DEX_DOCKER_CMD - alternative command passed to docker run
#
# DEX_X11_FLAGS - typically appended to org.dockerland.dex. in the .env file of
#                S images providing X11 applications

DEX_X11_FLAGS=${DEX_X11_FLAGS:-"-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY"}

v1-runtime(){
  [ -z "$__image" ] && echo "missing runtime image" && exit 1

  # augment defaults with image meta
  local prefix="org.dockerland.dex"
  for label in host_home host_workspace docker_flags; do
    # @TODO reduce this to a single docker inspect command
    val=$(docker inspect --format "{{ index .Config.Labels \"$prefix.$label\" }}" $__image)
    [ -z "$val" ] && continue
    eval "__$label=$val"
  done

  DEX_HOST_HOME=${DEX_HOST_HOME:-$__host_home}
  DEX_HOST_WORKSPACE=${DEX_HOST_WORKSPACE:-$__host_workspace}
  DEX_DOCKER_FLAGS=${DEX_DOCKER_FLAGS:-$__docker_flags}
  DEX_DOCKER_ENTRYPOINT=${DEX_DOCKER_ENTRYPOINT:-$__docker_entypoint}
  DEX_DOCKER_CMD=${DEX_DOCKER_CMD:-$__docker_cmd}

  #@TODO implement piping & redirection detection

  [ -z "$DEX_DOCKER_ENTRYPOINT"] && \
    DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS --entrypoint=$DEX_DOCKER_ENTRYPOINT"

  if tty -s >/dev/null 2>&1; then
    DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS -e DEX_PIPED=false"
    __pipe=
  else
    # piping into a container requires interactive
    DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS --interactive -e DEX_PIPED=true"
    __pipe="cat - |"
  fi
  
  eval $__pipe docker run $DEX_DOCKER_FLAGS \
    -v $DEX_HOST_HOME:/dex/home \
    -v $DEX_HOST_WORKSPACE:/dex/workspace \
    -e HOME=/dex/home \
    -e DEX_API=$DEX_API \
    --rm --workdir=/dex/workspace -u $(id -u):$(id -g) --log-driver=none \
    $__image $DEX_DOCKER_CMD $@

  return $?
}
