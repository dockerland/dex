#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_main(){
  cat <<-EOF

Piping hot docker executables to your door.

Usage: dex <command> [options]

  dex run --pull sed
  dex run sed s/foo/bar/ <(echo 'foo')
  dex run sed:darwin -h

Commands:

  help <command>                Display help for a particular command
  image <command> [options]     Build and maintain images
  install <imgstr>* [options]   Install a dexecutable to \$DEX_BIN_DIR
  source <command> [options]    Manage source repositories
  run <imgstr>* [options]       Execute an image
  uninstall <imgstr>* [options] Uninstall a dexecutable
  vars [options]                print configuration variables (and/or defaults)

* <imgstr> is a multi-form string defined as "[source/]<image[*]>[:tag]" and is
  used to lookup image(s), optionally filtering by source name and/or tag

Options:

  -h|--help                    Display help

EOF
}
