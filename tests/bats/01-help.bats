#!/usr/bin/env bats

load dex

setup(){
  [ -e $DEX ] || install_dex
}

@test "dex exits with status code 2 when no arguments are passed" {
  run $DEX
  [ $status -eq 2 ]
}

@test "dex exits with status code 127 when invalid argument passed" {
  run $DEX invalid-argument
  [ $status -eq 127 ]
}

@test "dex prints helpful output matching our fixture" {
  diff <(cat_fixture help.txt) <($DEX --help)
  diff <(cat_fixture help.txt) <($DEX -h)
  diff <(cat_fixture help.txt) <($DEX help)
}
