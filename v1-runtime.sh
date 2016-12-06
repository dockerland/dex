#!/usr/bin/env bash

v1-runtime(){
  # deactivate docker-machine
  docker/deactivate_machine

  DEX_HOME=${DEX_HOME:-~/.dex}
  [ -z "$__image" ] && { echo "missing runtime image" ; exit 1 ; }
  IFS=":" read -r __name __tag <<< "$__image"

  read -d "\n" DEX_HOST_UID DEX_HOST_GID DEX_HOST_USER DEX_HOST_GROUP DEX_HOST_PWD DEX_IMAGE_NAME < <(
    exec 2>/dev/null ; id -u ; id -g ; id -un ; id -gn ; pwd ; basename $__name ) || true

  # label defaults -- images may provide a org.dockerland.dex.<var> label
  #  supplying a value that overrides these default values, examples are:
  #
  #  org.dockerland.dex.docker_devices=/dev/shm   (shm mounted as /dev/shm)
  #  org.dockerland.dex.docker_envars="LANG TERM !MYAPP_" (passthru LANG & TERM & MYAPP_*)
  #  org.dockerland.dex.docker_flags=-it          (interactive tty)
  #  org.dockerland.dex.docker_groups=tty         (adds 'tty' to container user)
  #  org.dockerland.dex.docker_home=~             (user's actual home)
  #  org.dockerland.dex.docker_volumes=/etc/hosts:/etc/hosts:ro
  #  org.dockerland.dex.docker_workspace=/        (host root as /dex/workspace)
  #  org.dockerland.dex.host_docker=rw            (expose host's docker socket and passthru docker vars)
  #  org.dockerland.dex.host_paths=rw             (rw mount host HOME and CWD)
  #  org.dockerland.dex.host_users=ro             (augment container's /etc/passwd and /etc/group files [in read-only mode] with current host's uid|gid)
  #  org.dockerland.dex.window=yes                (applies window/X11 flags)
  #
  __docker_devices=
  __docker_envars="LANG TZ"
  __docker_flags=
  __docker_groups=
  __docker_home=$DEX_IMAGE_NAME-$__tag
  __docker_workspace=$DEX_HOST_PWD
  __docker_volumes=
  __host_docker=
  __host_paths="ro"
  __host_users=

  __window=

  # augment defaults with image meta
  for label in runtime docker_devices docker_envars docker_flags docker_groups docker_home docker_workspace docker_volumes host_docker host_paths host_users window ; do
    # @TODO reduce this to a single docker inspect command
    val=$(docker inspect --type image --format "{{ index .Config.Labels \"org.dockerland.dex.$label\" }}" $__image)
    [ -z "$val" ] && continue
    eval "__$label=\"$val\""
  done

  # rutime defaults -- override these by passing run flags, or through
  # exporting the following vars:
  #
  # DEX_DOCKER_CMD - alternative command passed to docker run
  # DEX_DOCKER_ENTRYPOINT - alternative entrypoint passed to docker run
  # DEX_DOCKER_FLAGS - additional flags passed to docker
  #
  # DEX_DOCKER_HOME - host directory mounted as the container's $HOME
  # DEX_DOCKER_WORKSPACE - host directory mounted as the container's CWD
  #
  # DEX_DOCKER_GID - gid to run the container under
  # DEX_DOCKER_UID - uid to run the container under
  #
  # DEX_DOCKER_LOG_DRIVER - docker logging driver
  # DEX_WINDOW_FLAGS - flags applied to windowed/X11 images
  #
  DEX_DOCKER_CMD=${DEX_DOCKER_CMD:-}
  DEX_DOCKER_ENTRYPOINT=${DEX_DOCKER_ENTRYPOINT:-}
  DEX_DOCKER_FLAGS=${DEX_DOCKER_FLAGS:-}

  DEX_DOCKER_HOME=${DEX_DOCKER_HOME:-$__docker_home}
  DEX_DOCKER_HOME=${DEX_DOCKER_HOME/#\~/$HOME}
  DEX_DOCKER_WORKSPACE=${DEX_DOCKER_WORKSPACE:-$__docker_workspace}

  DEX_DOCKER_GID=${DEX_DOCKER_GID:-$DEX_HOST_GID}
  DEX_DOCKER_UID=${DEX_DOCKER_UID:-$DEX_HOST_UID}

  DEX_DOCKER_LOG_DRIVER=${DEX_DOCKER_LOG_DRIVER:-'none'}
  DEX_WINDOW_FLAGS=${DEX_WINDOW_FLAGS:-"-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY"}
  DEX_PERSIST=${DEX_PERSIST:-false}

  [ -z "$__runtime" ] && \
    { echo "$__image did not specify an org.dockerland.dex.runtime label!" ; exit 1 ; }

  # if home is not an absolute path, make relative to $DEX_HOME/homes/
  [ "${DEX_DOCKER_HOME:0:1}" != '/' ] && \
    DEX_DOCKER_HOME=$DEX_HOME/homes/$DEX_DOCKER_HOME

  [ -d "$DEX_DOCKER_HOME" ] || mkdir -p $DEX_DOCKER_HOME || \
    { echo "unable to stub home directory: $DEX_DOCKER_HOME" ; exit 1 ; }

  [ -d "$DEX_DOCKER_WORKSPACE" ] || \
    { echo "workspace is not a directory: $DEX_DOCKER_WORKSPACE" ; exit 1 ; }

  [ -z "$DEX_DOCKER_ENTRYPOINT" ] || \
    __docker_flags+=" --entrypoint=$DEX_DOCKER_ENTRYPOINT"

  [ -z "$DEX_DOCKER_FLAGS" ] || \
    __docker_flags+=" --entrypoint=$DEX_DOCKER_FLAGS"

  $DEX_PERSIST || __docker_flags+=" --rm"

  # piping to|from a container requires interactive, non-tty input
  if [ ! -t 1 ] || ! tty -s > /dev/null 2>&1 ; then
    __docker_flags+=" --interactive=true --tty=false"
  fi

  # apply windowing vars (if window=true)
  case $(echo "$__window" | awk '{print tolower($0)}') in true|yes|on)
      __docker_flags+=" $DEX_WINDOW_FLAGS -e DEX_WINDOW=true"
      __docker_groups+=" audio video"
      __docker_devices+=" dri snd video video0"
      __docker_volumes+=" /dev/shm /var/lib/dbus/machine-id:/var/lib/dbus/machine-id:ro /etc/machine-id:/etc/machine-id:ro"

      # @TODO bats testing
      [ -z "$XDG_RUNTIME_DIR" ] || {
        __docker_flags+=" -v $XDG_RUNTIME_DIR:/var/run/xdg -e XDG_RUNTIME_DIR=/var/run/xdg"
      }

      # append xauth
      # @TODO test under fedora, opensuse, ubuntu
      # @TODO bats testing
      type xauth &>/dev/null && {
        __xauth=$DEX_HOME/.xauth
        touch $__xauth && \
          xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $__xauth nmerge - &>/dev/null && \
          __docker_flags+=" -v $__xauth:/tmp/.xauth -e XAUTHORITY=/tmp/.xauth"
      }

      # lookup CONFIG_USER_NS (e.g. for chrome sandbox),
      #   and add SYS_ADMIN cap if missing
      type zgrep &>/dev/null && {
        zgrep CONFIG_USER_NS=y /proc/config.gz &>/dev/null || \
          __docker_flags+=" --cap-add=SYS_ADMIN"
      }
      ;;
  esac

  # mount typical host paths to coax common absolute path resolutions
  case $(echo "$__host_paths" | awk '{print tolower($0)}') in rw|ro)
    if [[ ! "$HOME" =~ ^($DEX_HOST_PWD|/dex/home)$ ]]; then
      __docker_volumes+=" $HOME:$HOME:$__host_paths"
    fi
    if [[ ! "$DEX_HOST_PWD" =~ ^($HOME|/dex/workspace|/|/bin|/dev|/etc|/lib|/lib64|/opt|/proc|/sbin|/run|/sbin|/srv|/sys|/usr|/var)$ ]]; then
      __docker_volumes+=" $DEX_HOST_PWD:$DEX_HOST_PWD:$__host_paths"
    fi
  esac

  # map host /etc/passwd and /etc/group in container
  case $(echo "$__host_users" | awk '{print tolower($0)}') in rw|ro)
    container_sha=$(dex-image-build-container $__image) || {
      echo "dex runtime failed to spawn a build container"
      exit 1
    }
    container_dir=$DEX_HOME/build-containers/$container_sha
    [ -d $container_dir ] || mkdir -p $container_dir
    [ -e $container_dir/passwd ] || docker cp $container_sha:/etc/passwd $container_dir/passwd
    [ -e $container_dir/group ] || docker cp $container_sha:/etc/group $container_dir/group

    # augment /etc/passwd and /etc/group files with current user (if !already exists)
    grep -q ":$DEX_HOST_UID:$DEX_HOST_GID:" $container_dir/passwd || \
      echo "$DEX_HOST_USER:x:$DEX_HOST_UID:$DEX_HOST_UID:gecos:/dex/home:/bin/sh" >> $container_dir/passwd
    grep -q ":$DEX_HOST_GID:" $container_dir/group || \
      echo "$DEX_HOST_GROUP:x:$DEX_HOST_GID:" >> $container_dir/group

    __docker_volumes+=" $container_dir/passwd:/etc/passwd:$__host_users $container_dir/group:/etc/group:$__host_users"
  esac

  # map host docker socket and passthru docker vars
  case $(echo "$__host_docker" | awk '{print tolower($0)}') in rw|ro)
    __docker_socket=${DOCKER_SOCKET:-/var/run/docker.sock}
    [ -S $__docker_socket ] || {
      echo "image requests docker, but $__docker_socket is not a valid socket"
      exit 1
    }
    __docker_volumes+=" $__docker_socket:/var/run/docker.sock:$__host_docker $DOCKER_CERT_PATH $MACHINE_STORAGE_PATH"
    __docker_flags+=" --group-add=$(ls -ln $__docker_socket | awk '{print $4}')"
    __docker_envars+=" DOCKER_* MACHINE_STORAGE_PATH"
  esac

  # mount specicified devices (only if they exist)
  for path in $__docker_devices; do
    [ "${path:0:5}" = "/dev/" ] || path="/dev/$path"
    [ -e $path ] && __docker_flags+=" --device=$path"
  done

  # mount specified volumes (only if they exist)
  for path in $__docker_volumes; do
    IFS=":" read path_host path_container path_mode <<< "$path"
    path_host=${path_host/#\~/$HOME}
    [ -e "$path_host" ] || continue
    __docker_flags+=" -v $path_host:${path_container:-$path_host}:${path_mode:-rw}"
  done

  # add specified groups (only if they exist)
  for group in $__docker_groups; do
    gid=$(find/gid_from_name $group)
    [ -z "$gid" ] || __docker_flags+=" --group-add=$gid"
  done

  # assign passthru envars (if empty)
  # @TODO can probably refactor here...
  __vars=""
  for var in $__docker_envars; do
    if [[ $var == *"*" ]]; then
      eval "for var in \${!$var}; do __vars+=\" \$var\" ; done"
    else
      __vars+=" $var"
    fi
  done
  for var in $__vars; do
    eval "[ -z \"\$$var\" ] || __docker_flags+=\" -e $var=\$$var\""
  done

  ${DEX_DEBUG:=false} && __exec="echo"
  ${__exec:-exec} docker run $__docker_flags \
    -e DEX_DOCKER_HOME=$DEX_DOCKER_HOME \
    -e DEX_DOCKER_WORKSPACE=$DEX_DOCKER_WORKSPACE \
    -e DEX_HOST_GID=$DEX_HOST_GID \
    -e DEX_HOST_GROUP=$DEX_HOST_GROUP \
    -e DEX_HOST_PWD=$DEX_HOST_PWD \
    -e DEX_HOST_UID=$DEX_HOST_UID \
    -e DEX_HOST_USER=$DEX_HOST_USER \
    -e DEX_HOST_HOME=$HOME \
    -e DEX_IMAGE=$__image \
    -e DEX_IMAGE_NAME=$DEX_IMAGE_NAME \
    -e DEX_IMAGE_TAG=$__tag \
    -e HOME=/dex/home \
    -u $DEX_DOCKER_UID:$DEX_DOCKER_GID \
    -v $DEX_DOCKER_HOME:/dex/home \
    -v $DEX_DOCKER_WORKSPACE:/dex/workspace \
    --log-driver=$DEX_DOCKER_LOG_DRIVER \
    --workdir=/dex/workspace \
    $__image $DEX_DOCKER_CMD $@
}
