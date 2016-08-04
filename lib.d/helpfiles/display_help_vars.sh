#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_image(){
  cat <<-EOF
  
Piping hot docker executables to your door.

Variable Defaults:
  DEX_HOME: ~/.dex/
  DEX_BINDIR: /usr/local/bin/
  DEX_PREFIX: d

Usage: dex vars [options]

  # refresh checkout of all source repositories
  dex update

Options:

  -h|--help|help        Display help
  -d|--defaults         evaluate output to set/restore defaults.

EOF
}
