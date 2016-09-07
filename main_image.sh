#
# lib.d/main_image.sh for dex -*- shell-script -*-
#

#@TODO implement package building (in repositories as well -- symlink strategy)
#@TODO implement --pull to update sources
#@TODO fix argparsing, build only accepts a single argument

main_image(){
  local operand="display_help"
  local operand_args=

  __force_flag=false
  __skip_namespace=false
  QUIET_FLAG=

  if [ $# -eq 0 ]; then
    display_help 2
  else
    set -- $(normalize_flags_first "" "$@")
    while [ $# -ne 0 ]; do
      case $1 in
        -f|--force)       __force_flag=true ;;
        -h|--help)        display_help ;;
        -q|--quiet)       QUIET_FLAG="-q" ;;
        -a|--all)         __skip_namespace=true ;;
        --)               shift ; operand_args="$@" ; break ;;
        -*)               unrecognized_flag $1 ;;
        build|rm|ls)      operand="dex-image-$1"
                          __imgstr=$2
                          shift
                          ;;
        *)                unrecognized_arg "$1" ;;
      esac
      shift
    done
  fi

  dex-init
  $operand $operand_args
  exit $?

}
