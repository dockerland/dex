#
# lib.d/main_run.sh for dex -*- shell-script -*-
#

main_run(){
  local operand="display_help"
  local operand_args=

  # defaults
  __build_flag=false
  __pull_flag=false
  __interactive_flag=false
  __persist_flag=false

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in
        -b|--build)     __build_flag=true ;;
        -p|--pull)      __build_flag=true ; __pull_flag=true ;;
        -i|-t)          __interactive_flag=true ;;
        -h|--help)      display_help ;;
        --cmd)          DEX_DOCKER_CMD="$2" ; shift ;;
        --entrypoint)   DEX_DOCKER_ENTRYPOINT="$2" ; shift ;;
        --home)         DEX_DOCKER_HOME="$2" ; shift ;;
        --log-driver)   DEX_DOCKER_LOG_DRIVER="$2" ; shift ;;
        --persist)      __persist_flag=true ;;
        --gid|--group)  DEX_DOCKER_GID="$2" ; shift ;;
        --uid|--user)   DEX_DOCKER_UID="$2" ; shift ;;
        --workspace)    DEX_DOCKER_WORKSPACE="$2" ; shift ;;
        --)             shift ; operand_args="$@" ; break ;;
        -*)             unrecognized_flag $1 ;;
        *)              __imgstr="$1"
                        shift
                        operand="dex-run"
                        operand_args="$@"
                        break ;;
      esac
      shift
    done
  fi

  dex-init
  $operand $operand_args
  exit $?
}
