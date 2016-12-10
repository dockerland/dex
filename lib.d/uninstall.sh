#
# lib.d/main_uninstall.sh for dex -*- shell-script -*-
#

main_uninstall(){
  local operand="die/help"
  local operand_args=

  if [ $# -eq 0 ]; then
    die/help 2
  else
    set -- $(args/normalize_flags_first "" "$@")
    while [ $# -ne 0 ]; do
      case $1 in
        -h|--help)         die/help ;;
        --)                shift ; operand_args="$@" ; break ;;
        -*)                args/unknown "$1" "flag" ;;
        *)                 args/unknown "$1" "command" ;;
      esac
      shift
    done
  fi

  die "uninstall not yet implemented"

  $operand $operand_args
  exit $?

}
