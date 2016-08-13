#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help() {
  [ "$(type -t display_help_$__cmd)" = "function" ] || error \
    "missing helpfile for $__cmd" "is $__cmd a valid command?"

  display_help_$__cmd
  [ -z "$1" ] && exit 0
  exit $1
}
