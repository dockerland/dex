#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_update(){
  cat <<-EOF

Piping hot docker executables to your door.

To live is to iterate.

Usage: dex update [options]

  # refresh checkout of all source repositories
  dex update

Options:

  -h|--help|help        Display help
  -f|--force            When pulling, discard any working copy changes.

EOF
}
