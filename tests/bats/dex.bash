#!/usr/bin/env bash

# source helpers if not loaded
[ $HELPERS_LOADED ] || . $BATS_TEST_DIRNAME/helpers.bash

# define path to dex executable
DEX=$TMPDIR/usr/local/bin/dex

DEX_CMDS="
image
install
remote
run
uninstall
update
vars"

#
# runtime fns
#

install_dex(){
  (>&2 cd $REPO_ROOT ; make DESTDIR=$TMPDIR install ; )
  [ -x $DEX ] || error "failed installing dex"
}
