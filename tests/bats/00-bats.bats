#!/usr/bin/env bats

load helpers

@test "helpers get loaded" {
  [ $HELPERS_LOADTED ]
}
