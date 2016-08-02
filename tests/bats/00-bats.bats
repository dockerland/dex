#!/usr/bin/env bats

load helpers

@test "helpers get loaded" {
  [ $HELPERS_LOADED ]
}

@test "writable TMPDIR" {
  touch $TMPDIR/writable
}
