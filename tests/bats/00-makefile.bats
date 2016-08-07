#!/usr/bin/env bats

#
# 00 - dependencies
#

load helpers

setup() {
  cd $REPO_ROOT
}

@test "makefile compiles dex" {
  rm -rf $REPO_ROOT/bin/dex
  make
  [ -e $REPO_ROOT/bin/dex ]
}

@test "makefile installs an executable dex" {
  make DESTDIR=$TMPDIR install
  [ -x $TMPDIR/usr/local/bin/dex ]
}

@test "makefile uninstalls dex" {
  make DESTDIR=$TMPDIR uninstall
  [ ! -e $TMPDIR/usr/local/bin/dex ]
}

@test "makefile cleans up" {
  make clean
  [ ! -e $REPO_ROOT/bin/dex ]
}
