#!/usr/bin/env bats

load dex

setup(){
  [ -e $DEX ] || install_dex
}

@test "vars prints helpful output matching our fixture" {
  diff <(cat_fixture help-vars.txt) <($DEX vars --help)
  diff <(cat_fixture help-vars.txt) <($DEX vars -h)
  diff <(cat_fixture help-vars.txt) <($DEX help vars)
}
