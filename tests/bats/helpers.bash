#!/usr/bin/env bash

HELPERS_LOADED=true
REPO_ROOT=${REPO_ROOT:-"$(git rev-parse --show-toplevel)"}

# path to writable test target
TMPDIR=$BATS_TMPDIR/dex-tests
mkdir -p $TMPDIR

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
