#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_update(){
  cat <<-EOF

Piping hot docker executables to your door.

To live is to iterate.

Usage: dex update <name|url>

  # refresh checkout of all source repositories
  dex update all

  # refresh checkout of the core repository
  dex update core

Options:

  -h|--help|help        Display help
  -f|--force            When pulling, discard any working copy changes.

EOF
}
