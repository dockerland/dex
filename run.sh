main_run(){
  local operand="dex/run"
  local list=()
  local build=false
  DEX_DOCKER_FLAGS=${DEX_DOCKER_FLAGS:-}

  [ $# -eq 0 ] && die/help 1
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        die/help ;;
      -b|--build)
        build=true ;;
      -p|--pull)
        build=true ; __pull=true ;;
      --persist)
        DEX_PERSIST=true ;;
      -i|-t|-it|--interactive)
        DEX_DOCKER_FLAGS+=" -it" ;;
      --cmd)
        DEX_DOCKER_CMD="$2" ; shift ;;
      --entrypoint)
        DEX_DOCKER_ENTRYPOINT="$2" ; shift ;;
      --home)
        DEX_DOCKER_HOME="$2" ; shift ;;
      --log-driver)
        DEX_DOCKER_LOG_DRIVER="$2" ; shift ;;
      --gid|--group)
        DEX_DOCKER_GID="$2" ; shift ;;
      --uid|--user)
        DEX_DOCKER_UID="$2" ; shift ;;
      --workspace)
        DEX_DOCKER_WORKSPACE="$2" ; shift ;;
      --)
        shift ; list=( "$@" ) ; break ;;
      -*)
        args/unknown "$1" "flag" ;;
      *)
        list+=( "$@" )
        break
        ;;
    esac
    shift
  done
  shell/execfn "$operand" "${list[@]}"
}

dex/run(){
  local repostr="$1" ; shift
  [ -z "$repostr" ] && {
    p/shout "an image must be specified to run"
    die/help 2
  }

  # ensure :latest if no image tag is passed
  repostr="$(dex/get-repostr "$repostr" "latest")" || {
    die "bad repostr ($repostr) passed to run"
  }

  # build
  if $build || [ -z "${__image:=$(dex/get-image "$repostr")}" ]; then
    dex/image-build "$repostr" || return 1
    __image="$(dex/get-image "$repostr")"
  fi
  api="$(docker/local inspect --type image --format "{{ index .Config.Labels \"org.dockerland.dex.runtime\" }}" $__image)"
  [ -z "$api" ] && {
    die/exception "failed determing runtime for $repostr from $__image image"
  }

  __repotag=$(docker/get/repotag $__image)
  __name="${__repotag##*/}"
  __name="${__name%%:*}"
  __tag="${__repotag##*:}"
  shell/execfn ${api:-$DEX_RUNTIME}-runtime "$@"
}

# dex/run/mk-reference - add image reference files for use by runtime.
#                        useful for augmenting a container's host|group files.
dex/run/mk-reference(){
  local repotag="$1"
  local path="$(dex/get/reference-path "$repotag")"
  local name="$(docker/get/safe-name "$repotag" "reference" )"

  (
    exec >&2
    docker/machine-deactivate
    docker rm --force $name &>/dev/null || true

    # start reference container
    docker run --label org.dockerland.dex.reference=yes --entrypoint=false --name=$name $repotag

    # copy files into reference directory
    rm -rf "$path" && mkdir -p "$path"
    docker cp $name:/etc/passwd $path/passwd
    docker cp $name:/etc/group $path/group

    # remove reference container
    docker rm --force $name &>/dev/null || true
  )

}
