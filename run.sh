main_run(){
  local operand
  local list=()
  local build=false
  DEX_DOCKER_FLAGS=${DEX_DOCKER_FLAGS:-}
  __image=

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
  local repo
  local image
  local tag
  IFS="/:" read repo image tag <<< "$(dex/find-repostr $repostr)"

  [ -z "$image" ] && {
    io/shout "an image must be specified to run"
    display_help 2
  }

  __image="$DEX_NAMESPACE/$image:${tag:-latest}"
  api=$(docker/local inspect --type image --format "{{ index .Config.Labels \"org.dockerland.dex.runtime\" }}" $__image)
  [ -z "$api" ] && build=true
  $build && {
    dex/image-build "$repostr" || return 1
  }
  shell/execfn ${api:-$DEX_RUNTIME}-runtime "$@"
}
