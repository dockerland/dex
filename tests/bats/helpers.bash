#!/usr/bin/env bash

#BATS_TEST_DIRNAME=<autoloaded by bats>-
NAMESPACE=dex
REPO_ROOT=${REPO_ROOT:-"$(git rev-parse --show-toplevel)"}
TMPDIR=$BATS_TEST_DIRNAME/tmp

#
# bootstrap
#

# ready the $TMPDIR on first run
[ -z "$HELPERS_LOADED" ] && {
  mkdir -p $TMPDIR
}

HELPERS_LOADED=true

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
