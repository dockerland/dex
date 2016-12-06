#!/usr/bin/env bats

#
# 90 - post/cleanup
#

load app

setup(){
  export DEX_NETWORK=false
}

@test "network refuses to fetch from git remotes when disabled" {
  run $APP repo pull core
  [[ "$output" == *"networking is disabled"* ]]

  $SKIP_NETWORK_TEST && continue

  export DEX_NETWORK=true
  run $APP repo pull core
  [[ "$output" != *"networking is disabled"* ]]

}

@test "network refuses to fetch sources.list when disabled" {
  run $APP repo reset
  [[ "$output" == *"sources.list"* ]]
  [[ "$output" == *"networking is disabled"* ]]
}
