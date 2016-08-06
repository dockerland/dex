#!/usr/bin/env bats

#
# 05 - runtime
#

load dex

setup(){
  [ -e $DEX ] || install_dex
}

teardown(){
  rm -rf $DEX_HOME
}

@test "remote ls displays sources.list matching our fixture" {
  diff <(cat_fixture remote-ls.txt) <($DEX remote ls)
}

@test "remote add requires name and url" {

}

@test "remote add|ls|rm errors with 127 if missing sources.list" {
  for cmd in add ls rm; do
    run $DEX remote $cmd junk junk
    [ $status -eq 127 ]
  done
}

@test "remote add updates sources.list" {

}

@test "remote add supports local reference repository checkouts" {

}

@test "remote add refuses to duplicate existing names" {

}

@test "remote add refuses to duplicate existing URLs" {

}

@test "remote add refuses to add sources it cannot clone" {

}

@test "remote add refuses to add sources it cannot clone by reference" {

}

@test "remote add refuses to add sources if a named checkout already exists" {

}

@test "remote add --force overwrites existing names" {

}

@test "remote add --force overwrites existing URLs" {

}

@test "remote add --force overwrites existing checkouts" {

}

@test "remote pull errors if it is passed an invalid <name|url>" {

}

@test "remote pull creates a new checkout if it is non-existant" {

}

@test "remote pull updates a checkout if it already exists" {

}

@test "remote pull exits with status code 126 if it encounters unwritable checkouts" {

}

@test "remote pull errors if it is unable to update a local checkout" {

}

@test "remote rm errors if it is passed an invalid <name|url>" {

}

@test "remote rm errors with status code 126 if it encounters unwritable checkouts" {

}

@test "remote rm removes entry from sources.list and its associated checkout" {

}
