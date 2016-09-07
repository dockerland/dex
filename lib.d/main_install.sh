#
# lib.d/main_install.sh for dex -*- shell-script -*-
#

main_install(){
  local operand="display_help"
  local operand_args=

  __force_flag=false
  __global_flag=false
  __pull_flag=false

  if [ $# -eq 0 ]; then
    display_help 2
  else
    set -- $(normalize_flags_first "" "$@")
    while [ $# -ne 0 ]; do
      case $1 in
        -f|--force)       __force_flag=true ;;
        -g|--global)      __global_flag=true ;;
        -p|--pull)        __pull_flag=true ;;
        -h|--help)        display_help ;;
        --)               shift ; operand_args="$@" ; break ;;
        -*)               unrecognized_flag $1 ;;
        *)                operand="dex-install"
                          __imgstr=$1
                          ;;
      esac
      shift
    done
  fi

  $operand $operand_args
  exit $?
}
