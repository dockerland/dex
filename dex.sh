#!/usr/bin/env bash

#
# dex
#

CWD=$(dirname $0)

main(){

  CMD="main"

  local runstr="display_help"

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in
        help)             CMD=${2:-$CMD} ; display_help ;;
        image)            CMD=$1 ; shift ; main_$CMD $@ ;;
        -h|--help)        display_help ;;
        *)                unrecognized_arg "$1" ;;
      esac
      shift
    done
  fi

  $runstr
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
