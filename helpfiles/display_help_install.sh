#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_image(){
  cat <<-EOF
Piping hot docker executables to your door.

Installing a dexecutable will build its image and copy its launch script
to $DEX_BINDIR (typically /usr/local/bin). The script is prefixed using
$DEX_PREFIX (typically 'd'), so installing 'sed' creates /usr/local/bin/dsed.

You may 'globally' install, which will create a symlink to the dexecutable
without a prefix, so /usr/local/bin/sed points to /usr/local/bin/dsed.

Installed executables
  * launch faster than 'dex run <image>', as they avoid the repository search.
  * always execute the same [version] of the image built when installed --
    whereas 'dex run <image>' attempts to run the latest after a repository pull

Usage: dex install [repository/]<image> [options]

  # Install a dexecutable (creates 'dsed' and 'dsed-darwin' in /usr/local/bin)
  dex install sed
  dex install sed:darwin

  # Install a dexecutable from a specific source repository
  dex install extras/sed

  # Globally install a dexecutable (creates 'sed' in /usr/local/bin)
  dex install --global sed:darwin


Options:

  -h|--help|help        Display help

  -g|--global           Globally install the dexecutable

  -f|--force            Overwrite target(s) if they already exist.

EOF
}
