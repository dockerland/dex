#!/usr/bin/env bats

#
# 07 - runtime
#

load dex

export DEX_NAMESPACE="dex/v1-tests"

setup(){
  [ -e $DEX ] || install_dex
  mk-images
}

@test "run errors if it cannot find an image" {
  run $DEX run imgtest/certainly-missing
  [ $status -eq 1 ]
}

@test "run automatically builds (and runs) image" {
  run $DEX image --force rm imgtest/*
  run $DEX run imgtest/debian
  echo $output
  [ $status -eq 0 ]
  [[ $output == *"built imgtest/debian"* ]]
  [[ $output == *"DEBIAN_RELEASE"* ]]
}

@test "run supports piping of stdin" {
  local out=$(echo "foo" | $DEX run imgtest/debian sed 's/foo/bar/')
  [ $? -eq 0 ]
  [ "$out" = "bar" ]
}
