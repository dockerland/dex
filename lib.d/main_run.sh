#
# lib.d/main_run.sh for dex -*- shell-script -*-
#

main_run(){

  local runstr="display_help"
  __build_flag=false
  __pull_flag=false

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do

      case $1 in
        -b|--build)       __build_flag=true ;;
        -p|--pull)        __build_flag=true ; __pull_flag=true ;;
        --persist)        DEX_DOCKER_PERSIST=true ;;
        -h|--help)        display_help ;;
        *)                arg_var "$1" LOOKUP && {
                            shift
                            dex-init
                            dex-run $@
                            exit $?
                          } ;;
      esac
      shift
    done
  fi

  dex-init
  $runstr
  exit $?
}
