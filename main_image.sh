#
# lib.d/main_image.sh for dex -*- shell-script -*-
#

#@TODO implement package building (in repositories as well -- symlink strategy)
#@TODO implement --pull to update sources
#@TODO fix argparsing, build only accepts a single argument

main_image(){

  local runstr="display_help"
  __force_flag=false
  __skip_namespace=false
  QUIET_FLAG=

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do

      case $1 in
        build|rm|ls)      runstr="dex-image-$1"
                          arg_var "$2" LOOKUP && shift
                          ;;
        -f|--force)       __force_flag=true ;;
        -h|--help)        display_help ;;
        -q|--quiet)       QUIET_FLAG="-q" ;;
        -a|--all)         __skip_namespace=true ;;
        *)                unrecognized_arg "$1" ;;
      esac
      shift
    done
  fi

  dex-init
  $runstr
  exit $?

}
