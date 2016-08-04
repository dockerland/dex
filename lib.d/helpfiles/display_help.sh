#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help() {
  display_help_$1 || error "missing helpfile fn"
  [ -z "$2" ] && exit 0
  exit $2
}
