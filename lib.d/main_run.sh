#
# lib.d/main_run.sh for dex -*- shell-script -*-
#

main_run(){

  local runstr="display_help"
  __build_flag=false
  __pull_flag=false
  __interactive_flag=false
  __persist_flag=false

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do

      case $1 in
        -b|--build)       __build_flag=true ;;
        -p|--pull)        __build_flag=true ; __pull_flag=true ;;
        -i|-it)           __interactive_flag=true ;;
        -h|--help)        display_help ;;
        --cmd)            arg_var "$2" DEX_DOCKER_CMD && shift ;;
        --entrypoint)     arg_var "$2" DEX_DOCKER_ENTRYPOINT && shift ;;
        --gid|--group)    arg_var "$2" DEX_DOCKER_GID && shift ;;
        --home)           arg_var "$2" DEX_DOCKER_HOME && shift ;;
        --log-driver)     arg_var "$2" DEX_DOCKER_LOG_DRIVER && shift ;;
        --persist)        __persist_flag=true ;;
        --uid|--user)     arg_var "$2" DEX_DOCKER_UID && shift ;;
        --workspace)      arg_var "$2" DEX_DOCKER_WORKSPACE && shift ;;
        *)                arg_var "$1" __imgstr && {
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
