display_help_conf(){
  cat <<-EOF

dex - run applications without installing them or their dependencies.

Usage:
  dex conf [options...] <command>

Options:
  -h|--help
    Displays help

  -d|--defaults
    Temporarily resets the current environment and prints default values

Commands:
  vars [-d|--defaults] [--] [list...]
    Prints configuration variables as evaluable output
    Examles:
      # print current environment configuration variables
      dex conf vars

      # print configuration variable defaults
      dex conf vars --defaults

      # prints the default value for DEX_BIN_PREFIX
      dex conf --defaults vars -- DEX_BIN_PREFIX

EOF
}
