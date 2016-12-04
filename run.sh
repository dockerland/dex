main_run(){
  local operand
  local list=()
  local build=false
  DEX_DOCKER_FLAGS=${DEX_DOCKER_FLAGS:-}

  [ $# -eq 0 ] && display_help 1
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        display_help ;;
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
        operand="dex/run"
        list+=( "$1" )
        ;;
    esac
    shift
  done
  shell/execfn "$operand" "${list[@]}"
}

dex/run(){
  local repostr="$1" ; shift
  [ -z "$repostr" ] && {
    io/shout "an image must be specified to run"
    display_help 2
  }
  __image="$(dex/find-image "$repostr")"

  if $build || [ -z "$__image" ]; then
    dex/image-build "$repostr" || return 1
    __image="$(dex/find-image "$repostr")"
  fi

  api="$(docker/local inspect --type image --format "{{ index .Config.Labels \"org.dockerland.dex.runtime\" }}" $__image)"
  [ -z "$api" ] && {
    die/exception "failed determing runtime for $repostr from $__image image"
  }

  shell/execfn ${api:-$DEX_RUNTIME}-runtime "$@"
}
