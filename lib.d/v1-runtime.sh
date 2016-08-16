#!/usr/bin/env bash

v1-runtime(){
  [ -z "$__image" ] && echo "missing runtime image" && exit 1

  # runtime defaults,
  #  images may provide a org.dockerland.dex.<var> label supplying a value
  #  that overrides these default values, examples are:
  #  org.dockerland.dex.docker_home
  #  org.dockerland.dex.docker_workspace
  #  org.dockerland.dex.docker_flags

  __docker_home=~
  __docker_workspace=$(pwd)
  __docker_flags=
  __docker_entypoint=
  __docker_cmd=

  __docker_persist=false
  __docker_uid=$(id -u)
  __docker_gid=$(id -g)
  __docker_log_driver="none"

  # You may override these by exporting the following vars:
  #
  # DEX_DOCKER_HOME - docker host directory mounted as the container's $HOME
  # DEX_DOCKER_WORKSPACE - docker host directory mounted as the container's CWD
  # DEX_DOCKER_FLAGS - flags passed to docker run
  # DEX_DOCKER_ENTRYPOINT - alternative entrypoint passed to docker run
  # DEX_DOCKER_CMD - alternative command passed to docker run
  #
  # DEX_DOCKER_UID - uid to run the container under
  # DEX_DOCKER_GID - gid to run the container under
  #
  # DEX_DOCKER_LOG_DRIVER - logging driver to use for container
  # DEX_DOCKER_PERSIST - when false, container is removed after it exits
  #
  # DEX_X11_FLAGS - typically appended to org.dockerland.dex. in the .env file of
  #                S images providing X11 applications


  DEX_X11_FLAGS=${DEX_X11_FLAGS:-"-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY"}
  DEX_DOCKER_FLAGS=${DEX_DOCKER_FLAGS:-$__docker_flags}

  # augment defaults with image meta
  local prefix="org.dockerland.dex"
  for label in docker_home docker_workspace docker_flags; do
    # @TODO reduce this to a single docker inspect command
    val=$(docker inspect --format "{{ index .Config.Labels \"$prefix.$label\" }}" $__image)
    [ -z "$val" ] && continue
    eval "__$label=$val"
  done

  [ -z "${DEX_DOCKER_ENTRYPOINT:=$__docker_entypoint}" ] || \
    DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS --entrypoint=$DEX_DOCKER_ENTRYPOINT"

  ${DEX_DOCKER_PERSIST:=$__docker_persist} || \
    DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS --rm"

  if tty -s >/dev/null 2>&1; then
    DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS -e DEX_PIPED=false"
    __pipe=
  else
    # piping into a container requires interactive
    DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS --interactive -e DEX_PIPED=true"
    __pipe="cat - |"
  fi

  eval $__pipe docker run $DEX_DOCKER_FLAGS \
    -v ${DEX_DOCKER_HOME:-$__docker_home}:/dex/home \
    -v ${DEX_DOCKER_WORKSPACE:-$__docker_workspace}:/dex/workspace \
    -e HOME=/dex/home \
    -e DEX_API=$DEX_API \
    -u ${DEX_DOCKER_UID:-$__docker_uid}:${DEX_DOCKER_GID:-$__docker_gid} \
    --log-driver=${DEX_DOCKER_LOG_DRIVER:-$__docker_log_driver} \
    --workdir=/dex/workspace \
    $__image ${DEX_DOCKER_CMD:-$__docker_cmd} $@

  return $?
}
