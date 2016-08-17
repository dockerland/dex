#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_install(){
  cat <<-EOF
Piping hot docker executables to your door.

Installing dexecutables builds their image and copies their runtime script to
\$DEX_BIN_DIR (usually /usr/local/bin). The script is prefixed using
\$DEX_BIN_PREFIX (usually 'd'), so installing 'sed' creates /usr/local/bin/dsed.

You may 'globally' install, which will create a symlink to the dexecutable
without a prefix, so /usr/local/bin/sed points to /usr/local/bin/dsed and
can be executed as plain old 'sed' as if it were installed locally.

Be sure your PATH prioritizes \$DEX_BIN_DIR if you want to run dexecutable
versions instead of OS installed ones.

Installed executables
  * launch faster than 'dex run <image>', as they avoid the repository search.
  * always execute the same [version] of the image built when installed --
    whereas 'dex run <image>' attempts to run the latest after a repository pull

Usage: dex install [options] <imgstr>*

  # Install a dexecutable (creates 'dsed' and 'dsed-macos' in /usr/local/bin)
  dex install sed
  dex install sed:macos

  # Install a dexecutable from a specific source repository
  dex install extras/sed

  # Globally install a dexecutable (creates 'sed' in /usr/local/bin)
  dex install --global sed:macos

* <imgstr> is a multi-form string defined as "[source/]<image[*]>[:tag]" and is
  used to lookup image(s), optionally filtering by source name and/or tag

Options:

  -h|--help|help        Display help
  -p|--pull             Refresh checkout(s) before building+installing
  -g|--global           Globally install the dexecutable
  -f|--force            Overwrite target(s) if they already exist.

EOF
}
