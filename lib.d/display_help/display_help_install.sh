display_help_install(){
  cat <<-EOF

dex - run applications without installing them or their dependencies.

About install:

Images are built and installed as prefixed scripts to \$DEX_BIN_DIR. Installing
'sed' will create \${DEX_BIN_DIR}/\${DEX_BIN_PREFIX}sed, e.g.
  $DEX_BIN_DIR/${DEX_BIN_PREFIX}sed

Prioritize \$DEX_BIN_DIR in your \$PATH to prefer dex installed images to system
installed binaries.

Installed images launch faster than 'dex run <image>' as they avoid a repository
search. They also guarantee execution of the same image built when installed.

Usage:
  dex install [options...] <[repository]/image[:tag]...>

Options:
  -h|--help
    Displays help
  -f|--force
    Overwrites targets in \$DEX_BIN_DIR if they already exist.
  -g|--global
    Creates a non-prefixed symlink to the installed script.
  -p|--pull
    Pull (refresh) repositories before building.

Examples:
  # Install sed (creates 'dsed' and 'dsed-macos' in /usr/local/bin)
  dex install sed sed:macos

  # Globally install all images from the extra repository
  dex install --global extra/

EOF
}
