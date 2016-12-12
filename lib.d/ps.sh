main_ps(){
  local operand="dex/ps"
  local list=()
  local global=false
  local quiet=false

  set -- $(args/normalize_flags_first "" "$@")
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        die/help ;;
      -a|--all)
        global=true ;;
      -q|--quiet)
        quiet=true ;;
      --)
        shift ; list=( "$@" ) ; break ;;
      -*)
        args/unknown "$1" "flag" ;;
      *)
        list+=( "$1" )
        ;;
    esac
    shift
  done

  shell/execfn "$operand" "${list[@]}"
}


dex/ps(){
  [ ${#@} -eq 0 ] && set -- ""
  local repostr
  local repo
  local image
  local tag
  for repostr in "$@"; do
    IFS="/:" read repo image tag <<< "$(dex/get-repostr $repostr)"

    if $global; then
      local flags=(
        "--filter=label=org.dockerland.dex.namespace"
      )
    else
      local flags=(
        "--filter=\"label=org.dockerland.dex.namespace=$DEX_NAMESPACE\""
      )
    fi

    [ -n "$image" ] && flags+=( "--filter=label=org.dockerland.dex.image=$image" )
    [ -n "$repo" ] && flags+=( "--filter=label=org.dockerland.dex.repo=$repo" )
    [ -n "$tag" ] && flags+=( "--filter=label=org.dockerland.dex.tag=$tag" )
    $quiet && flags+=( "-q" )

    docker/local ps -a ${flags[@]}

  done
}
