#!/usr/bin/env bats

load dex

setup(){
  [ -e $DEX ] || install_dex
}

@test "help exits with status code 2 when no arguments are passed" {
  run $DEX
  [ $status -eq 2 ]
}

@test "help exits with status code 127 when invalid argument passed" {
  run $DEX invalid-argument
  [ $status -eq 127 ]
}

@test "help prints helpful output matching our fixture" {
  diff <(cat_fixture help.txt) <($DEX --help)
  diff <(cat_fixture help.txt) <($DEX -h)
  diff <(cat_fixture help.txt) <($DEX help)
}

@test "help is provided for all dex commands" {
  for cmd in $DEX_CMDS ; do
    run $DEX help $cmd
    [ $status -eq 0 ]
  done
}

@test "help is provided whenever -h or --help flags are passed to a command" {
  for cmd in $DEX_CMDS ; do
    diff <($DEX $cmd -h) <($DEX help $cmd)
    diff <($DEX $cmd --help) <($DEX help $cmd)
  done
}

@test "help exits with status code 2 when no arguments are passed to a command" {
  for cmd in $DEX_CMDS ; do
    run $DEX $cmd
    [ $status -eq 2 ]
  done
}

@test "help exits with status code 127 when invalid arguments are passed to a command" {
  for cmd in $DEX_CMDS ; do
    run $DEX $cmd invalid-argument
    [ $status -eq 127 ]
  done
}
