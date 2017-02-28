#
# lib.d/main_uninstall.sh for dex -*- shell-script -*-
#

main_uninstall(){
  local operand="dex/uninstall"
  local operand_args=

  args/normalize_flags_first "" "$@"
  set -- "${__argv[@]}"
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        die/help ;;
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

  dex/get/engine-info >/dev/null
  shell/execfn "$operand" "${list[@]}"
}

dex/uninstall(){
  die "uninstall not yet implemented"
}
