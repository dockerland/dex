#!/usr/bin/env bash

#
# dex
#

CWD=$(dirname $0)

main(){

  CMD="main"
  ORIG_CMD="$0 $@"

  # DEX_HOME: dex workspace : ~/.dex
  # DEX_BINDIR: location where dex installs : /usr/local/bin
  # DEX_PREFIX: prefix of dexecutabls : d
  # DEX_NETWORK: enables network fetching : true

  DEX_VARS=( DEX_HOME DEX_BINDIR DEX_PREFIX DEX_NETWORK DEX_API )
  vars_load ${DEX_VARS[@]}

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in

        image|install|remote|run|uninstall|update|vars)
          CMD=$1 ; shift ; main_$CMD $@ ;;

        ping)             dex-ping ;;
        help)             CMD=${2:-$CMD} ; display_help ;;
        runfunc)          shift ; runfunc $@ ; exit $? ;;
        -h|--help)        display_help ;;
        *)                unrecognized_arg "$1" ;;

      esac
      shift
    done
  fi

  exit $?
}

#@start dev-mode
# replaced by make (lib.d/ shell scripts get expanded inline)
for helper in $(find $CWD/lib.d/ -type f -name "*.sh"); do
  #@TODO check for errors when sourcing here
  . $helper
done
main "$@"
#@end dev-mode