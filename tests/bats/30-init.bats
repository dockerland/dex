#!/usr/bin/env bats

#
# 30 - initialization and configuration
#

load app

@test "init creates writable DEX_HOME" {
  rm -rf "$DEX_HOME"
  run $APP
  [ -w "$DEX_HOME" ]
}

@test "init creates sources.list, writable checkout checkouts" {
  rm -rf "$DEX_HOME"
  run $APP
  [ -w "$DEX_HOME/checkouts" ]
}

@test "init generates default sources.list" {
  rm -rf "$DEX_HOME"
  run $APP
  grep -q "core" "$DEX_HOME/sources.list"
  grep -q "extra" "$DEX_HOME/sources.list"
}

@test "init exits with status code 126 if DEX_HOME is not writable" {
  rm -rf "$DEX_HOME"
  mkdir -p "$DEX_HOME" && chmod 000 "$DEX_HOME"
  run $APP
  chmod 755 "$DEX_HOME" && rm -rf "$DEX_HOME"
  [ $status -eq 126 ]
}

@test "init - bats init stubs our sources.list fixture" {
  [ -e "$DEX_HOME/sources.list" ]
  diff "$DEX_HOME/sources.list" <(fixture/cat "sources.list")

}
