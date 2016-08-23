#!/usr/bin/env bash

v1-runtime(){
  [ -z "$__image" ] && { echo "missing runtime image" ; exit 1 ; }

  # label defaults -- images may provide a org.dockerland.dex.<var> label
  #  supplying a value that overrides these default values, examples are:
  #
  #  org.dockerland.dex.docker_devices=/dev/shm   (shm mounted as /dev/shm)
  #  org.dockerland.dex.docker_envars="LANG TERM" (passthru LANG & TERM)
  #  org.dockerland.dex.docker_flags=-it          (interactive tty)
  #  org.dockerland.dex.docker_home=~             (user's actual home)
  #  org.dockerland.dex.docker_volumes=/etc/hosts:/etc/hosts:ro
  #  org.dockerland.dex.docker_workspace=/        (host root as /dex/workspace)
  #
  __docker_devices=
  __docker_envars="LANG TZ"
  __docker_flags=
  __docker_home=~
  __docker_workspace=$(pwd)
  __docker_volumes=

  # augment defaults with image meta
  for label in api docker_devices docker_envars docker_flags docker_home docker_workspace docker_volumes ; do
    # @TODO reduce this to a single docker inspect command
    val=$(docker inspect --format "{{ index .Config.Labels \"org.dockerland.dex.$label\" }}" $__image)
    [ -z "$val" ] && continue
    eval "__$label=\"$val\""
  done

  ${__interactive_flag:-false} && __docker_flags+=" --tty --interactive"
  ${__persist_flag:-false} || __docker_flags+=" --rm"

  # rutime defaults -- override these by passing run flags, or through
  # exporting the following vars:
  #
  # DEX_DOCKER_CMD - alternative command passed to docker run
  # DEX_DOCKER_ENTRYPOINT - alternative entrypoint passed to docker run
  #
  # DEX_DOCKER_HOME - host directory mounted as the container's $HOME
  # DEX_DOCKER_WORKSPACE - host directory mounted as the container's CWD
  #
  # DEX_DOCKER_GID - gid to run the container under
  # DEX_DOCKER_UID - uid to run the container under
  #
  # DEX_DOCKER_LOG_DRIVER - docker logging driver
  # DEX_X11_FLAGS - used by X11 images via org.dockerland.dex.docker_flags label
  #
  DEX_DOCKER_CMD=${DEX_DOCKER_CMD:-}
  DEX_DOCKER_ENTRYPOINT=${DEX_DOCKER_ENTRYPOINT:-}

  DEX_DOCKER_HOME=${DEX_DOCKER_HOME:-$__docker_home}
  DEX_DOCKER_WORKSPACE=${DEX_DOCKER_WORKSPACE:-$__docker_workspace}

  DEX_DOCKER_GID=${DEX_DOCKER_GID:-$(id -g)}
  DEX_DOCKER_UID=${DEX_DOCKER_UID:-$(id -u)}

  DEX_DOCKER_LOG_DRIVER=${DEX_DOCKER_LOG_DRIVER:-'none'}
  DEX_X11_FLAGS=${DEX_X11_FLAGS:-"-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY"}

  [ -z "$__api" ] && \
    { "$__image did not specify an org.dockerland.dex.api label!" ; exit 1 ; }

  # if home is not an absolute path, make relative to $DEX_HOME/<api>-homes/
  [[ "$DEX_DOCKER_HOME" != '/'* ]] && \
    DEX_DOCKER_HOME=${DEX_HOME:-~/dex}/$__api-homes/$DEX_DOCKER_HOME

  [ -d "$DEX_DOCKER_HOME" ] || mkdir -p $DEX_DOCKER_HOME || \
    { echo "unable to stub home directory: $DEX_DOCKER_HOME" ; exit 1 ; }

  [ -d "$DEX_DOCKER_WORKSPACE" ] || \
    { echo "workspace is not a directory: $DEX_DOCKER_WORKSPACE" ; exit 1 ; }

  [ -z "$DEX_DOCKER_ENTRYPOINT" ] || \
    __docker_flags+=" --entrypoint=$DEX_DOCKER_ENTRYPOINT"

  # piping into a container requires interactive, non-tty input
  ! tty -s >/dev/null 2>&1 && {
    __docker_flags+=" --interactive=true --tty=false"
  }

  # mount specicified devices (only if they exist)
  for path in $__docker_devices; do
    [[ "$path" == "/dev/"* ]] || path="/dev/$path"
    [ -e $path ] && __docker_flags+=" --device=$path"
  done

  # mount specified volumes (only if they exist)
  for path in $__docker_volumes; do
    IFS=":" read path_host path_container path_mode <<<$path
    [ -e "$path_host" ] || continue
    __docker_flags+=" -v $path_host:${path_container:-$path_host}:${path_mode:-rw}"
  done

  # pass specified passthru envars (only if defined)
  for var in $__docker_envars; do
    eval "val=\$$var"
    [ -z "$val" ] || __docker_flags+=" -e $var=$val"
  done

  exec docker run $__docker_flags \
    -e DEX_API=$__api \
    -e DEX_DOCKER_HOME=$DEX_DOCKER_HOME \
    -e DEX_DOCKER_WORKSPACE=$DEX_DOCKER_WORKSPACE \
    -e HOME=/dex/home \
    -u $DEX_DOCKER_UID:$DEX_DOCKER_GID \
    -v $DEX_DOCKER_HOME:/dex/home \
    -v $DEX_DOCKER_WORKSPACE:/dex/workspace \
    --log-driver=$DEX_DOCKER_LOG_DRIVER \
    --workdir=/dex/workspace \
    $__image $DEX_DOCKER_CMD $@

  return $?
}
