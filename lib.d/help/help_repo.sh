p/help_repo(){
  cat <<-EOF

dex - run applications without installing them or their dependencies.

About repo:
  dex images are built from Dockerfiles in git repositories.

  Repositories are defined one-per-line in \$DEX_HOME/sources.list in a
  space-delimited "<name> <url>" format -- and this command manages them.

  Repositories are cloned to \$DEX_HOME/checkouts when added, and refreshed when
  the --pull flag is passed to dex run|install, or explicitly via dex repo pull.

  Removing or adding repositories will not effect installed images, allowing
  dexecutables to function as normal. Use the "dex image" command to
  manage images built from sources.

Usage:
  dex repo [options...] <command>

Options:
  -h|--help
    Displays help

Commands:
  add [-f|--force] <name> <url>
    Add a source repository. <name> must be alphanumeric, and <url> can be
    a git remote or local path. Forcing overwrites existing <name>.
    Examples:
      dex repo add extra git@github.com:dockerland/dex-dockerfiles-extra.git
      dex repo add local /path/to/my/repo

  ls [-d|--defaults] [name(s)...]
    Print repositories from \$DEX_HOME/sources.list. Passing name(s) limits the
    listing. Passing defaults prints the $DEX_RUNTIME default sources.list.

  pull [-f|--force] [name(s)...]
    Pull (refresh) named repositories, or all repositories if no name passed.
    Forcing overwrites any working copy changes in \$DEX_HOME/checkouts/<name>
    Examples:
      dex repo pull
      dex repo pull local extra

  rm [-f|--force] <name(s)...>
    Remove named source repositories. Forcing disregards working copy changes.
    Examples:
      dex repo rm local --force

  reset [-f|--force]
    Reset sources.list to $DEX_RUNTIME default. Forcing supresses prompts and
    enables networking.

EOF
}
