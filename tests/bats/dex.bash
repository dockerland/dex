#!/usr/bin/env bash

# source helpers if not loaded
[ $HELPERS_LOADED ] || . $BATS_TEST_DIRNAME/helpers.bash

# define path to dex executable
DEX=$TMPDIR/usr/local/bin/dex

DEX_CMDS=( image install "source" run uninstall vars )
DEX_VARS=( DEX_HOME DEX_BIN_DIR DEX_BIN_PREFIX DEX_NETWORK DEX_API  )

export DEX_HOME=/tmp/dex-home
export DEX_NETWORK=false
export IMAGES_FILTER="--filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE"

SKIP_NETWORK_TEST=${SKIP_NETWORK_TEST:-false}

#
# runtime fns
#

install_dex(){
  (>&2 cd $REPO_ROOT ; make DESTDIR=$TMPDIR install ; )
  [ -x $DEX ] || error "failed installing dex"
}


mk-repo(){
  MK_REPO=$TMPDIR/local-repo
  [ -e $MK_REPO/.git ] && return 0
  git init $MK_REPO || return 1
  (
    cd $MK_REPO
    echo "content" > file
    git add file || exit 1
    git commit -m "initial commit" || exit 1
  )

  return $?
}

mk-images(){
  if [ ! -d $DEX_HOME/checkouts/imgtest ]; then
    (
      set -e
      mk-repo
      rm -rf $MK_REPO/images
      cp_fixture images/ $MK_REPO
      cd $MK_REPO
      git add images
      git commit -m "adding image fixtures"
      $DEX source --force add imgtest $MK_REPO
    ) || error "failed stubbing imgtest"

  fi
}

rm-images(){
  for image in $(docker images -q $IMAGES_FILTER); do
    docker rmi --force $image
  done
}
