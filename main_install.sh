#
# lib.d/main_install.sh for dex -*- shell-script -*-
#

main_install(){

  local runstr="display_help"
  __force_flag=false
  __global_flag=false
  __pull_flag=false

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in
        -f|--force)       __force_flag=true ;;
        -g|--global)      __global_flag=true ;;
        -p|--pull)        __pull_flag=true ;;
        -h|--help)        display_help ;;
        *)                arg_var "$1" __imgstr && {
                            shift
                            runstr="dex-install"
                          } ;;
      esac
      shift
    done
  fi

  $runstr
  exit $?
}
