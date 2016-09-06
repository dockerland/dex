#!/usr/bin/env bash

HELPERS_LOADED=true
NAMESPACE=dex
REPO_ROOT=${REPO_ROOT:-"$(git rev-parse --show-toplevel)"}
TMPDIR=/tmp/$NAMESPACE-tests
#BATS_TEST_DIRNAME=<autoloaded by bats>-

#
# bootstrap
#

mkdir -p $TMPDIR/home

# stub git config if we're in docker container and .git is missing
if [ $IN_TEST_CONTAINER ] && [ ! -d $TMPDIR/home/.git ]; then
  git config --global user.email "tests-container@$NAMESPACE.git"
  git config --global user.name "Tests Docker"
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
