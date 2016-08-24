#!/usr/bin/env bash

#
# dex
#

main(){

  __cmd="main"
  __entrypoint="$0 $@"
  __dex_build="@DEX_BUILD@"
  __dex_version="@DEX_VERSION@"

  # DEX_API: api version: v1
  # DEX_BIN_DIR: location where dex installs : /usr/local/bin
  # DEX_BIN_PREFIX: prefix of dexecutabls : d
  # DEX_HOME: dex workspace : ~/.dex
  # DEX_NAMESPACE: prefix used when tagging image builds : dex/<DEX_API>, dex/v1
  # DEX_NETWORK: enables network fetching : true

  DEX_VARS=( DEX_API DEX_BIN_DIR DEX_BIN_PREFIX DEX_HOME DEX_NAMESPACE DEX_NETWORK )
  dex-vars-init ${DEX_VARS[@]}

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in

        image|install|source|run|uninstall|update|vars)
          __cmd=$1 ; shift ; main_$__cmd "$@" ;;

        ping)             dex-ping ;;
        help)             __cmd=${2:-$__cmd} ; display_help ;;
        runfunc)          shift ; runfunc "$@" ; exit $? ;;
        -h|--help)        display_help ;;
        -v|--version)     log "Dex version $__dex_version build $__dex_build" ;;
        *)                unrecognized_arg "$1" ;;

      esac
      shift
    done
  fi

  exit $?
}

#@start dev-mode
# replaced by make (lib.d/ shell scripts get expanded inline)
__cwd=$(dirname $0)
for helper in $(find $__cwd/lib.d/ -type f -name "*.sh"); do
  #@TODO check for errors when sourcing here
  . $helper
done
main "$@"
#@end dev-mode
