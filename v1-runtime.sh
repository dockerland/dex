#!/usr/bin/env bash

v1-runtime(){
  [ -z "$__image" ] && { echo "missing runtime image" ; exit 1 ; }

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

  # augment defaults with image meta
  local prefix="org.dockerland.dex"
  for label in api docker_home docker_workspace docker_flags; do
    # @TODO reduce this to a single docker inspect command
    val=$(docker inspect --format "{{ index .Config.Labels \"$prefix.$label\" }}" $__image)
    [ -z "$val" ] && continue
    eval "__$label=\"$val\""
  done

  DEX_DOCKER_FLAGS=${DEX_DOCKER_FLAGS:-$__docker_flags}
  DEX_HOME=${DEX_HOME:-~/.dex}
  DEX_X11_FLAGS=${DEX_X11_FLAGS:-"-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY"}
  __interactive_flag=${__interactive_flag:-false}

  [ -z "$__api" ] && \
    { "$__image did not specify an org.dockerland.dex.api label!" ; exit 1 ; }

  # if home is not an absolute path, make relative to $DEX_HOME/image-homes/
  [[ "$__docker_home" != '/'* ]] && \
    __docker_home=$DEX_HOME/$__api-homes/$__docker_home

  [ -d "${DEX_DOCKER_HOME:=$__docker_home}" ] || mkdir -p $DEX_DOCKER_HOME || \
    { echo "unable to stub home directory: $DEX_DOCKER_HOME" ; exit 1 ; }

  [ -d "${DEX_DOCKER_WORKSPACE:=$__docker_workspace}" ] || \
    { echo "workspace is not a directory: $DEX_DOCKER_WORKSPACE" ; exit 1 ; }

  [ -z "${DEX_DOCKER_ENTRYPOINT:=$__docker_entypoint}" ] || \
    DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS --entrypoint=$DEX_DOCKER_ENTRYPOINT"

  ${DEX_DOCKER_PERSIST:=$__docker_persist} || \
    DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS --rm"

  # piping into a container requires interactive
  ! tty -s >/dev/null 2>&1 && __interactive_flag=true
  $__interactive_flag && DEX_DOCKER_FLAGS="$DEX_DOCKER_FLAGS --interactive"

  exec docker run $DEX_DOCKER_FLAGS \
    -e DEX_API=$__api \
    -e DEX_DOCKER_HOME=$DEX_DOCKER_HOME \
    -e DEX_DOCKER_WORKSPACE=$DEX_DOCKER_WORKSPACE \
    -e HOME=/dex/home \
    -u ${DEX_DOCKER_UID:-$__docker_uid}:${DEX_DOCKER_GID:-$__docker_gid} \
    -v $DEX_DOCKER_HOME:/dex/home \
    -v $DEX_DOCKER_WORKSPACE:/dex/workspace \
    --log-driver=${DEX_DOCKER_LOG_DRIVER:-$__docker_log_driver} \
    --workdir=/dex/workspace \
    $__image ${DEX_DOCKER_CMD:-$__docker_cmd} $@

  return $?
}
