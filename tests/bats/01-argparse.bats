#!/usr/bin/env bats

load dex

setup(){
  [ -e $DEX ] || install_dex
}

@test "argparse recognizes ping command" {
  run $DEX ping
  [ $status -eq 0 ]
  [ "$output" = "pong" ]
}
