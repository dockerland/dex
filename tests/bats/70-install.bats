#!/usr/bin/env bats

#
# 70 - test command after-effects
#

load app

setup(){
  make/test-repo &>/dev/null
  app/var DEX_BIN_PREFIX
  app/var DEX_BIN_DIR
}

teardown(){
  chmod 755 "$DEX_BIN_DIR" || true
  rm -rf "$DEX_BIN_DIR"
}

@test "install errors if it cannot write(126)" {
  mkdir -p "$DEX_BIN_DIR"
  chmod 000 "$DEX_BIN_DIR"
  run $APP install test-repo/alpine
  [ $status -eq 126 ]
}


@test "install errors if it cannot match any image(s)" {
  run $APP install test-repo/certainly-missing
  [ $status -gt 0 ]
}

@test "install creates DEX_BIN dir and writes tag runtime and prefixed link" {
  run $APP install test-repo/alpine:latest
  [ $status -eq 0 ]

  [ -d "$DEX_BIN_DIR" ]
  [ -e "$DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine-latest" ]
  [ -L "$DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine" ]
}

@test "install writes _behaving dexecutables_ to DEX_BIN_DIR"  {
  run $APP install test-repo/debian:latest
  [ $status -eq 0 ]
  [ -x "$DEX_BIN_DIR/${DEX_BIN_PREFIX}debian" ]

  run "$DEX_BIN_DIR/${DEX_BIN_PREFIX}debian"
  [[ "$output" == *"DEBIAN_RELEASE"* ]]

  output=$(echo "foo" | $DEX_BIN_DIR/${DEX_BIN_PREFIX}debian sed 's/foo/bar/')
  [ "$output" = "bar" ]
}


@test "install prompts to overwrite existing files" {
  mkdir -p "$DEX_BIN_DIR"
  touch "$DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine"
  touch "$DEX_BIN_DIR/alpine"

  yes "n" | run $APP install --global test-repo/alpine
  [ -z "$(cat "$DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine")" ]
  [ ! -L "$DEX_BIN_DIR/alpine" ]

  yes "y" | run $APP install --global test-repo/alpine
  [ -n "$(cat "$DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine")" ]
  [ -L "$DEX_BIN_DIR/alpine" ]
}


@test "install respects --force flag" {
  mkdir -p "$DEX_BIN_DIR"
  touch "$DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine"
  touch "$DEX_BIN_DIR/alpine"

  $APP install --force --global test-repo/alpine
  [ -n "$(cat "$DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine")" ]
  [ -L "$DEX_BIN_DIR/alpine" ]
}


@test "install supports multiple repotags" {
  run $APP install --force :8 alpine:latest
  [ $status -eq 0 ]
  [ $(ls -1 "$DEX_BIN_DIR" | wc -l) -eq 4 ]
}

@test "install adds symlink to runtime script when --global flag is passed" {
  run $APP install --force --global test-repo/alpine:latest

  [ $status -eq 0 ]
  [ -e "$DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine" ]
  [ -L "$DEX_BIN_DIR/alpine" ]
}

@test "install complains if DEX_BIN_DIR not in PATH" {
  run $APP install --force --global test-repo/alpine
  [[ "$output" == *"DEX_BIN_DIR is missing from your PATH"* ]]

  export PATH="$DEX_BIN_DIR:$PATH"
  run $APP install --force --global test-repo/alpine
  [[ "$output" != *"DEX_BIN_DIR is missing from your PATH"* ]]

  export PATH="$PATH:$DEX_BIN_DIR"
  run $APP install --force --global test-repo/alpine
  [[ "$output" != *"DEX_BIN_DIR is missing from your PATH"* ]]
}

#@TODO test label failures, e.g. when org.dockerland.dex.api is missing
#@TODO test that installation of a repo installs _all_ images, and if no :latest, all versions of that image.
