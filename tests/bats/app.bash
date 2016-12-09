#!/usr/bin/env bash

# source helpers if not loaded
[ $HELPERS_LOADED ] || . "$BATS_TEST_DIRNAME/helpers.bash"

APP="$TMPDIR/usr/local/bin/dex"
SKIP_NETWORK_TEST=${SKIP_NETWORK_TEST:-false}


export DEX_HOME="$TMPDIR/home/.dex"
export DEX_NETWORK=false
export DEX_NAMESPACE="v1-tests"
#export IMAGES_FILTER="--filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE"

APP_CMDS=(
  conf
  image
  install
  ls
  repo
  run
)

APP_VARS=(
  DEX_BIN_DIR
  DEX_BIN_PREFIX
  DEX_HOME
  DEX_NAMESPACE
  DEX_NETWORK
  DEX_REGISTRY
  DEX_RUNTIME
)


#
# runtime fns
#

make/app(){
  (
    cd "$REPO_ROOT"
    make DESTDIR="$TMPDIR" install
  )
  [ -x "$APP" ] || die "failed installing application binary"
}

make/sources(){
  # stub our sources.list
  mkdir -p $DEX_HOME
  fixture/cp sources.list $DEX_HOME/sources.list
}

[ -e "$APP" ] || make/app &>/dev/null
[ -e "$DEX_HOME/sources.list" ] || make/sources &>/dev/null

#
# mk-repo(){
#   MK_REPO=$TMPDIR/local-repo
#   [ -e $MK_REPO/.git ] && return 0
#   git init $MK_REPO || return 1
#   (
#     cd $MK_REPO
#     echo "content" > file
#     git add file || exit 1
#     git commit -m "initial commit" || exit 1
#   )
#
#   return $?
# }
#
# mk-imgtest(){
#   if [ ! -d $DEX_HOME/checkouts/imgtest ]; then
#     (
#       set -e
#       mk-repo
#       rm -rf $MK_REPO/dex-images
#       cp_fixture dex-images/ $MK_REPO
#       cd $MK_REPO
#       git add dex-images
#       git commit -m "adding image fixtures"
#       $APP source --force add imgtest $MK_REPO
#     ) || error "failed stubbing imgtest"
#   fi
# }
#
# rm-images(){
#   for image in $(docker images -q $IMAGES_FILTER); do
#     docker rmi --force $image
#   done
