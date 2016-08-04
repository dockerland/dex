#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help() {
  [ "$(type -t display_help_$CMD)" = "function" ] || error \
    "missing helpfile for $CMD" "is $CMD a valid command?"

  display_help_$CMD
  [ -z "$1" ] && exit 0
  exit $1
}
