#!/usr/bin/env bash

v1-runtime(){

  #
  # initialization
  #

  [[ -z "$__repotag" || -z "$__name" || -z "$__tag" ]] && \
    die "\e[1m$FUNCNAME\e[21m - missing repotag ($__repotag), name ($__name), or tag ($__tag)"

  docker/local version >/dev/null || die "dex failed communicating with docker. is it running? do you have access to its socket?" "executing 'docker version' must succeed"

  # ensure DEX_HOME is absolute
  DEX_HOME=${DEX_HOME:-~/.dex}
  is/absolute "$DEX_HOME" || DEX_HOME="$(pwd)/$DEX_HOME"

  # it's faster to execute these in a single child process ...
  read -d "\n" DEX_HOST_UID DEX_HOST_GID DEX_HOST_USER DEX_HOST_GROUP DEX_HOST_PWD < <(
    exec 2>/dev/null ; id -u ; id -g ; id -un ; id -gn ; pwd  ) || true

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
  local docker_devices=
  local docker_envars="LANG TZ"
  local docker_flags=
  local docker_groups=
  local docker_home="$__name-$__tag"
  local docker_workspace="$DEX_HOST_PWD"
  local docker_volumes=
  local host_docker=
  local host_paths="ro"
  local host_users=
  local window=

  #
  # runtime assignments
  #

  # augment defaults with image labels
  local label
  local value
  while read label value ; do
    [[ -z "$label" || ! "${label:0:19}" == "org.dockerland.dex." ]] && continue #docker-cli injects newline...
    eval "${label/org.dockerland.dex.}=\"$value\""
  done < <(docker/local inspect --type image -f '{{range $key, $value := .Config.Labels }}{{println $key $value }}{{ end }}' $__repotag)

  # rutime defaults -- override through 'run' flags or exporting variables
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
  DEX_DOCKER_CMD="${DEX_DOCKER_CMD:-}"
  DEX_DOCKER_ENTRYPOINT="${DEX_DOCKER_ENTRYPOINT:-}"
  DEX_DOCKER_FLAGS="${DEX_DOCKER_FLAGS:-}"

  DEX_DOCKER_HOME="${DEX_DOCKER_HOME:-$docker_home}"
  DEX_DOCKER_HOME="${DEX_DOCKER_HOME/#\~/$HOME}"
  DEX_DOCKER_WORKSPACE="${DEX_DOCKER_WORKSPACE:-$docker_workspace}"

  DEX_DOCKER_GID="${DEX_DOCKER_GID:-$DEX_HOST_GID}"
  DEX_DOCKER_UID="${DEX_DOCKER_UID:-$DEX_HOST_UID}"

  DEX_DOCKER_LOG_DRIVER="${DEX_DOCKER_LOG_DRIVER:-none}"
  DEX_WINDOW_FLAGS="${DEX_WINDOW_FLAGS:-"-v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY"}"
  DEX_PERSIST="${DEX_PERSIST:-false}"

  # containers are removed by default...
  $DEX_PERSIST || docker_flags+=" --rm"

  # if home is not an absolute path, make relative to $DEX_HOME/homes/
  is/absolute "$DEX_DOCKER_HOME" || \
    DEX_DOCKER_HOME=$DEX_HOME/homes/$DEX_DOCKER_HOME

  [ -z "$DEX_DOCKER_ENTRYPOINT" ] || \
    docker_flags+=" --entrypoint=$DEX_DOCKER_ENTRYPOINT"

  [ -z "$DEX_DOCKER_FLAGS" ] || \
    docker_flags+=" $DEX_DOCKER_FLAGS"


  #
  # sanity
  #

  [ -z "$runtime" ] && \
    die "\e[1m$FUNCNAME\e[21m - $__repotag must provide a org.dockerland.dex.runtime label!"

  [ -d "$DEX_DOCKER_HOME" ] || mkdir -p $DEX_DOCKER_HOME || \
    die "\e[1m$FUNCNAME\e[21m - unable to stub home directory: $DEX_DOCKER_HOME"

  [ -d "$DEX_DOCKER_WORKSPACE" ] || \
    die "\e[1m$FUNCNAME\e[21m - workspace is not a directory: $DEX_DOCKER_WORKSPACE"



  #
  # label assignments
  #

  # apply windowing vars (if window=true)
  is/any "$window" "true" "yes" "on" && {
    docker_flags+=" $DEX_WINDOW_FLAGS -e DEX_WINDOW=true"
    docker_groups+=" audio video"
    docker_devices+=" dri snd video video0"
    docker_volumes+=" /dev/shm /var/lib/dbus/machine-id:/var/lib/dbus/machine-id:ro /etc/machine-id:/etc/machine-id:ro"

    # @TODO bats testing
    [ -z "$XDG_RUNTIME_DIR" ] || {
      docker_flags+=" -v $XDG_RUNTIME_DIR:/var/run/xdg -e XDG_RUNTIME_DIR=/var/run/xdg"
    }

    # append xauth
    # @TODO test under fedora, opensuse, ubuntu
    # @TODO bats testing
    type xauth &>/dev/null && {
      local xauth=$DEX_HOME/.xauth
      touch $xauth && \
        xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $xauth nmerge - &>/dev/null && \
        docker_flags+=" -v $xauth:/tmp/.xauth -e XAUTHORITY=/tmp/.xauth"
    }

    # lookup CONFIG_USER_NS (e.g. for chrome sandbox),
    #   and add SYS_ADMIN cap if missing
    type zgrep &>/dev/null && {
      zgrep CONFIG_USER_NS=y /proc/config.gz &>/dev/null || \
        docker_flags+=" --cap-add=SYS_ADMIN"
    }
  }

  # mount typical host paths to coax common absolute path resolutions
  is/any "$host_paths" "ro" "rw" && {
    if [[ ! "$HOME" =~ ^($DEX_HOST_PWD|/dex/home)$ ]]; then
      docker_volumes+=" $HOME:$HOME:$host_paths"
    fi
    if [[ ! "$DEX_HOST_PWD" =~ ^($HOME|/dex/workspace|/|/bin|/dev|/etc|/lib|/lib64|/opt|/proc|/sbin|/run|/sbin|/srv|/sys|/usr|/var)$ ]]; then
      docker_volumes+=" $DEX_HOST_PWD:$DEX_HOST_PWD:$host_paths"
    fi
  }

  # add real host user and group to container's /etc/passwd and /etc/group
  is/any "$host_users" "ro" "rw" && {
    reference_path="$(dex/get/reference-path $__repotag)"
    [ -d "$reference_path" ] || dex/run/mk-reference "$__repotag" || die \
      "\e[1m$FUNCNAME\e[21m - mk-reference failed"

    # augment /etc/passwd and /etc/group files with current user (if !already exists)
    grep -q ":$DEX_HOST_UID:$DEX_HOST_GID:" $reference_path/passwd || \
      echo "$DEX_HOST_USER:x:$DEX_HOST_UID:$DEX_HOST_UID:gecos:/dex/home:/bin/sh" >> "$reference_path/passwd"
    grep -q ":$DEX_HOST_GID:" $reference_path/group || \
      echo "$DEX_HOST_GROUP:x:$DEX_HOST_GID:" >> "$reference_path/group"

    docker_volumes+=" $reference_path/passwd:/etc/passwd:$host_users $reference_path/group:/etc/group:$host_users"
  }

  # map host docker socket and passthru docker vars
  is/any "$host_docker" "ro" "rw" && {
    local docker_socket="${DOCKER_SOCKET:-/var/run/docker.sock}"
    [ -S "$docker_socket" ] || \
      die "\e[1m$FUNCNAME\e[21m - image requests docker, but $docker_socket is not a valid socket"

    docker_volumes+=" $docker_socket:/var/run/docker.sock:$host_docker $HOME/.docker:/dex/home/.docker:$host_docker $DOCKER_CERT_PATH $MACHINE_STORAGE_PATH"
    docker_flags+=" --group-add=$(ls -ln $docker_socket | awk '{print $4}')"
    docker_envars+=" DOCKER_* MACHINE_STORAGE_PATH"
  }

  local path
  local group

  # mount specicified devices (only if they exist)
  for path in $docker_devices; do
    [ "${path:0:5}" = "/dev/" ] || path="/dev/$path"
    [ -e "$path" ] && docker_flags+=" --device=$path"
  done

  # mount specified volumes (only if they exist)
  for path in $docker_volumes; do
    IFS=":" read path_host path_container path_mode <<< "$path"
    path_host="${path_host/#\~/$HOME}"
    [ -e "$path_host" ] || continue
    docker_flags+=" -v $path_host:${path_container:-$path_host}:${path_mode:-rw}"
  done

  # add specified groups (only if they exist)
  for group in $docker_groups; do
    #@TODO should we test if group is numeric?
    gid="$(get/gid_from_name $group)"
    [ -z "$gid" ] || docker_flags+=" --group-add=$gid"
  done

  # assign passthru envars (if empty)
  local vars=()
  local var
  for var in $docker_envars; do
    if [[ "$var" == *"*" ]]; then
      eval "for var in \${!$var}; do vars+=( \"\$var\" ) ; done"
    else
      vars+=( "$var" )
    fi
  done
  for var in "${vars[@]}"; do
    eval "[ -z \"\$$var\" ] || docker_flags+=\" -e $var=\$$var\""
  done

  #
  # execution
  #

  # piping to a container requires interactive, non-tty input
  # lets do this last to take priority over earlier flags
  docker_flags+=" --interactive=true"
  if [ -t 0 ] && [ -t 1 ]; then
    docker_flags+=" --tty=true"
  else
    docker_flags+=" --tty=false"
  fi

  # deactivate docker-machine
  docker/deactivate-machine

  # allow debugging by passing DEX_DEBUG=true, e.g.
  #  DEX_DEBUG=true dex run sed ...
  local cmd="exec"
  ${DEX_DEBUG:=false} && cmd="echo"

  $cmd docker run $docker_flags \
    -e DEX_DOCKER_HOME=$DEX_DOCKER_HOME \
    -e DEX_DOCKER_WORKSPACE=$DEX_DOCKER_WORKSPACE \
    -e DEX_HOST_GID=$DEX_HOST_GID \
    -e DEX_HOST_GROUP=$DEX_HOST_GROUP \
    -e DEX_HOST_PWD=$DEX_HOST_PWD \
    -e DEX_HOST_UID=$DEX_HOST_UID \
    -e DEX_HOST_USER=$DEX_HOST_USER \
    -e DEX_HOST_HOME=$HOME \
    -e DEX_IMAGE=$__repotag \
    -e DEX_IMAGE_NAME=$__name \
    -e DEX_IMAGE_TAG=$__tag \
    -e HOME=/dex/home \
    -u $DEX_DOCKER_UID:$DEX_DOCKER_GID \
    -v $DEX_DOCKER_HOME:/dex/home \
    -v $DEX_DOCKER_WORKSPACE:/dex/workspace \
    --log-driver=$DEX_DOCKER_LOG_DRIVER \
    --workdir=/dex/workspace \
    $__repotag $DEX_DOCKER_CMD $@
}
