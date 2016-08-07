#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_main(){
  cat <<-EOF

Piping hot docker executables to your door.

Usage: dex <command> [options]

  dex run sed
  dex run sed s/foo/bar/ <(echo 'foo')
  dex run sed:darwin -h

Commands:

  help <command>               Display help for a particular command
  image <command>              Build and maintain images
  install [repository/]<image> Install a dexecutable to \$DEX_BIN_DIR
  remote <command>             Manage source repositories
  run [repository/]<image>     Run a dexecutable
  update                       Refreshes ("pulls") all source repositories
  uninstall <image>            Uninstall a dexecutable
  vars                         print configuration variables (and/or defaults)

Options:

  -h|--help                    Display help
EOF
}
