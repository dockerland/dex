#!/usr/bin/env bash

#BATS_TEST_DIRNAME=<autoloaded by bats>-
NAMESPACE=dex
REPO_ROOT=${REPO_ROOT:-"$(git rev-parse --show-toplevel)"}
TMPDIR="$BATS_TEST_DIRNAME/tmp"

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

fixture/cat(){
  local fixture="$(fixture/resolve "$1")"
  cat "$fixture"
}

fixture/cp(){
  local fixture="$(fixture/resolve "$1")"
  local target="$2"
  cp -R "$fixture" "$target"
}

fixture/resolve(){
  local fixture="$BATS_TEST_DIRNAME/fixtures/$1"
  [ -e $fixture ] || fixture="$BATS_TEST_DIRNAME/../fixtures/$1"
  echo "$fixture"
}


# allow shell helpers
source $REPO_ROOT/lib.d/helpers/shell-helpers.sh
