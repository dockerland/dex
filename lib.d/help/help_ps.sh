p/help_ls(){
  cat <<-EOF

dex - run applications without installing them or their dependencies.

About ps:

Lists executing and persisted and dex containers

Usage:
  dex ps [options...] [[repository]/image[:tag]...]

Options:
  -h|--help
    Displays help

  -b|--build
    include 'build' containers

  -a|--all
    additionally lists containers across runtimes

  -q|--quiet
    limit output to container shas

Examples:

  # List running and persisted containers from the extra/ repository
  dex ps extra/

EOF
}
