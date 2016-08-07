#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_vars(){
  cat <<-EOF

Piping hot docker executables to your door.

Variable Defaults:
  DEX_API: v1
  DEX_HOME: ~/.dex
  DEX_BIN_DIR: '/usr/local/bin'
  DEX_BIN_PREFIX: 'd'
  DEX_NETWORK: true
  DEX_TAG_PREFIX: dex/$DEX_API

Usage: dex vars [var] [options]

  # print all dex configuration vars and their resolved value
  dex vars all

  # print specific vars
  dex vars DEX_BIN_DIR DEX_BIN_PREFIX

  # print variable defaults (evalute output to restore)
  dex vars -d all
  dex vars -d DEX_HOME

Options:

  -h|--help|help        Display help
  -d|--defaults         evaluate output to set/restore defaults.

EOF
}
