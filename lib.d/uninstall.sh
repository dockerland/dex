#
# lib.d/main_uninstall.sh for dex -*- shell-script -*-
#

main_uninstall(){
  local operand="display_help"
  local operand_args=

  if [ $# -eq 0 ]; then
    display_help 2
  else
    set -- $(args/normalize_flags_first "" "$@")
    while [ $# -ne 0 ]; do
      case $1 in
        -h|--help)         display_help ;;
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
