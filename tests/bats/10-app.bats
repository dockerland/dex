#!/usr/bin/env bats

#
# 10 - basic application behavior and test prerequisites
#

load app

@test "app exists and is executable" {
  [ -x $APP ]
}

@test "app sources.list matches our fixture" {
  diff $DEX_HOME/sources.list <(fixture/cat sources.list)
}

@test "app supports runfunc" {
  run $APP runfunc abc_is_no_function
  [ $status -eq 2 ]
  [[ "$output" == *"abc_is_no_function"* ]]
}
