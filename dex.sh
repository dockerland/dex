#!/usr/bin/env bash

#
# dex
#

CWD=$(dirname $0)
runstr="display_help"

main(){
  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in
        -h|--help|help)    display_help ;;
        *)                 echo "$1 is an unrecognized argument";
                           display_help 127 ;;
      esac
      shift
    done

    $runstr
    exit $?
  fi
}

#@start dev-mode
# replaced by make (lib.d/ contents will expanded inline)
for helper in $CWD/lib.d/*.sh; do
  . $helper
done

main "$@"
#@end dev-mode
