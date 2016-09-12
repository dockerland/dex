#
# lib.d/main_uninstall.sh for dex -*- shell-script -*-
#

main_uninstall(){
  local operand="display_help"
  local operand_args=

  if [ $# -eq 0 ]; then
    display_help 2
  else
    set -- $(normalize_flags_first "" "$@")
    while [ $# -ne 0 ]; do
      case $1 in
        -h|--help)         display_help ;;
        --)                shift ; operand_args="$@" ; break ;;
        -*)                unrecognized_flag $1 ;;
        *)                 unrecognized_arg "$1" ;;
      esac
      shift
    done
  fi

  $operand $operand_args
  exit $?

}
