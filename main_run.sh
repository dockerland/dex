#
# lib.d/main_run.sh for dex -*- shell-script -*-
#

main_run(){

  local runstr="display_help"
  BUILD_FLAG=false
  PERSIST_FLAG=

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do

      case $1 in
        -b|--build)       BUILD_FLAG=true ;;
        -h|--help)        display_help ;;
        *)                arg_var "$1" LOOKUP && runstr="dex-run" ;;
      esac
      shift
    done
  fi

  dex-init
  $runstr
  exit $?
}
