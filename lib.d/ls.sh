main_ls(){
  local operand="dex/ls"
  local list=()
  local global=false

  set -- $(args/normalize_flags_first "" "$@")
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        display_help  ;;
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


dex/ls(){
  [ ${#@} -eq 0 ] && set -- ""
  local repostr
  local Dockerfile
  for repostr in "$@"; do
    for Dockerfile in $(dex/find-dockerfiles "$repostr" ""); do
      dex/find-repostr-from-dockerfile "$Dockerfile"
    done
  done
}
