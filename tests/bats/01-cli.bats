#!/usr/bin/env bats

#
# 01 - basic behavior
#

load dex

setup(){
  [ -e $DEX ] || install_dex
}

@test "cli recognizes ping command" {
  run $DEX ping
  [ $status -eq 0 ]
  [ "$output" = "pong" ]
}

@test "cli ping accepts positional args" {
  run $DEX ping "PING" "PONG"
  [ $status -eq 0 ]
  [ "$output" = "PING PONG" ]
} 

@test "cli supports runfunc" {
  run $DEX runfunc abc_is_no_function
  [ $status -eq 1 ]
  [[ "$output" == *"abc_is_no_function"* ]]
}

@test "cli normalize_flags routine supports POSIX short and long flags" {
  run $DEX runfunc normalize_flags \"\" \"-abc\"
  [ "$(echo $output | tr -d '\n')" = "-a -b -c" ]

  run $DEX runfunc normalize_flags \"om\" \"-abcooutput.txt\" \"--def=jam\" \"-mz\"
  [ "$(echo $output | tr -d '\n')" = "-a -b -c -o output.txt --def jam -m z" ]
}
