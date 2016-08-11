#!/usr/bin/env bats

#
# 03 - setup
#

load dex

setup(){
  [ -e $DEX ] || install_dex

  # start with a clean workspace and a disabled network
  rm -rf $DEX_HOME
}

teardown(){
  rm -rf $DEX_HOME
}

@test "setup creates a writable DEX_HOME" {
  run $DEX runfunc dex-init

  echo $output

  [ $status -eq 0 ]
  [ -d $DEX_HOME ]
  [ -w $DEX_HOME ]
}

@test "setup creates a writable checkout target" {
  run $DEX runfunc dex-init

  [ $status -eq 0 ]
  [ -d $DEX_HOME/checkouts ]
  [ -w $DEX_HOME/checkouts ]
}

@test "setup generates default sources.list matching our fixture" {
  run $DEX runfunc dex-init

  diff <(cat_fixture sources.list) $DEX_HOME/sources.list

}

@test "setup exits with status code 126 if DEX_HOME is not writable" {

  mkdir -p $DEX_HOME && chmod 000 $DEX_HOME
  run $DEX runfunc dex-init
  chmod 700 $DEX_HOME

  [ $status -eq 126 ]
}
