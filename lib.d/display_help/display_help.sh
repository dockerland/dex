#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help() {
  [ "$(type -t display_help_$1)" = "function" ] || error \
    "missing helpfile for $1" "is $1 a valid command?"

  display_help_$1
  [ -z "$2" ] && exit 0
  exit $2
}
