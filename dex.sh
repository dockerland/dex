#!/usr/bin/env bash

#
# dex
#

CWD=$(dirname $0)

#@start dev-mode
# replaced by make (lib.d/ contents will expanded inline)
for helper in $CWD/lib.d/*.sh; do
  . $helper
done
#@end dev-mode

runstr="display_help"

if [ $# -eq 0 ]; then
  display_help 1
else
  while [ $# -ne 0 ]; do
    case $1 in
      -h|--help|help)    display_help ;;
      *)                 echo "$1 is an unrecognized argument"; display_help 1 ;;
    esac
    shift
  done

  $runstr
  exit $?
fi
