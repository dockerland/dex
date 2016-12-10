p/help_main() {
  cat <<-EOF

dex - run applications without installing them or their dependencies.

Usage:
  dex <command> [options...]

Examles:
  # edit (from DOS!)
  dex run --pull edit a.txt

  # piping to SED (from darwin/macos)
  echo "foo" | dex run sed:macos s/foo/bar/

Options:
  -h|--help
    Displays help

  -v|--version|version
    Print version and exit

Commands:
  conf      Prints configurations
  help      Display help for a particulat command
  image     Build and maintain images from source repositories
  install   Installs an image to \$DEX_BIN_DIR
  ls        Lists images avaialbe in source repositories
  repo      Manage source repositories
  run       Executes an image

EOF
}
