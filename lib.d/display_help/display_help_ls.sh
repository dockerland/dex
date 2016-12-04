display_help_ls(){
  cat <<-EOF

dex - run applications without installing them or their dependencies.

About ls:

Lists images available in source repositories.

Usage:
  dex ls [options...] [[repository]/image[:tag]...]

Options:
  -h|--help
    Displays help

Examples:
  # List all available images
  dex ls

  # List images in the extra repository
  dex ls extra/

  # List 'sed' images across all repositories
  dex ls sed

  # list all available macos variants
  dex ls :macos

EOF
}
