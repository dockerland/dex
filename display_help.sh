#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help() {
cat <<-EOF

Piping hot docker executables to your door.

"dexecutables" are images built and executed from Dockerfiles and scripts
hosted in [git] source repositories.

Usage: dex <command> [options]

  # Run a dexecutable (below examples run sed)
  dex run sed
  echo 'foo' | dex run sed s/foo/bar/
  dex run sed s/foo/bar/ <(echo 'foo')

  # Run a tagged version of a dexecutable (below maps to sed/Dockerfile.darwin)
  dex run sed:darwin -h

  # Install a dexecutable (creates 'dsed' and 'dsed-darwin' in /usr/local/bin)
  dex install sed
  dex install sed:darwin

  # Install a dexecutable from a specific source repository
  dex install extras/sed

  # Globally install a dexecutable (creates 'sed' in /usr/local/bin)
  dex install --global sed:darwin

  # Add an additional dexecutable source repository named "extras"
  #  sources are stored in ~/dex/sources.list
  dex remote add extras|git@github.com:dockerland/dex-dockerfiles-extra.git


Commands:

  run [src/]<image>      Run a dexecutable. Prefixing with src/ will run a
                         dexecutable from a specific source repository.

  pull [src]             Pull changes from dexecutable source repositories,
                         or a specific source repository if named.

  install [src/]<image>  Installs a dexecutable to $DEX_BINDIR so it can be
                         run by name (vs. dex run image).
  uninstall              Removes a dexecutable from $DEX_BINDIR (and its global
                         counterpart if installed).

  remote-add [src|url]   Add (and pulls) a dexecutable source repository.
                         Accepts a source string, or prompts for name and url.
  remote-rm              Remove a dexecutable source repository
  remote-ls              List dexecutable source repositories


Options:
  -h|--help|help        Display help

  -t|--target           Target directory for (un)installations
                        (defaults $DEX_BINDIR:-'/usr/local/bin')

  -p|--prefix           Prefix to use when (un)installing dexecutables
                        (defaults to $DEX_PREFIX:-'d')

  -g|--global           Perform a global installation (without a prefix)

EOF

  [ $# -eq 0 ] && exit 0
  exit $1
}
