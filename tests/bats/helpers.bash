#!/usr/bin/env bash

HELPERS_LOADED=true
REPO_ROOT=${REPO_ROOT:-"$(git rev-parse --show-toplevel)"}

# path to writable test targets
TMPDIR=/tmp/dex-tests
mkdir -p $TMPDIR/home

# stub git config if we're in docker container and .git is missing
if [ $IN_TEST_CONTAINER ] && [ ! -d $TMPDIR/home/.git ]; then
  git config --global user.email "dex@dex-tests.com"
  git config --global user.name "Dex"
fi


#
# runtime fns
#

error(){
  printf "\033[31m%s\n\033[0m" "$@" >&2
  exit 1
}

cat_fixture(){
  local fixture=$BATS_TEST_DIRNAME/fixtures/$1
  [ -e $fixture ] || fixture=$BATS_TEST_DIRNAME/../fixtures/$1
  [ -e $fixture ] || error "unable to resolve fixture $1"

  cat $fixture
  return 0
}

cp_fixture(){
  local fixture=$BATS_TEST_DIRNAME/fixtures/$1
  [ -e $fixture ] || fixture=$BATS_TEST_DIRNAME/../fixtures/$1
  [ -e $fixture ] || error "unable to resolve fixture $1"

  cp -R $fixture $2
  return $?
}
