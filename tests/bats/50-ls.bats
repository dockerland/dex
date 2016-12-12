#!/usr/bin/env bats

#
# 50 - command behavior
#

load app

setup(){
  export REPO_DIR="$TMPDIR/test-repo"
  make/repo "$REPO_DIR"
  [ -d  "$REPO_DIR/dex-images" ] || (
    exec >/dev/null
    cd $REPO_DIR
    fixture/cp dex-images .
    git add dex-images
    git commit -m "adding dex-images"
  )

  [ -n "$($APP repo ls test-repo)" ] || \
    $APP repo add --force test-repo "$REPO_DIR"

  [ -n "$($APP repo ls test-other)" ] || \
    $APP repo add --force test-other "$REPO_DIR"
}

@test "ls prints available images from repositories" {
  run $APP ls
  # compare against our dex-imaages fixture
  [[ "$output" == *"test-repo/alpine:latest"* ]]
  [[ "$output" == *"test-repo/cachebust:nocache"* ]]
  [[ "$output" == *"test-repo/debian:latest"* ]]
  [[ "$output" == *"test-repo/debian:7"* ]]

  # image count should match
  [ "$(find/filtered "test-repo/*" $($APP ls) | wc -l)" = "$(find/filtered "test-other/*" $($APP ls) | wc -l)" ]
}

@test "ls supports filtering by repository" {
  run $APP ls test-repo/
  [[ "$output" == *"test-repo/"* ]]
  [[ "$output" != *"test-other/"* ]]
}

@test "ls supports filtering by image" {
  run $APP ls alpine debian
  [[ "$output" == *"/alpine:"* ]]
  [[ "$output" == *"/debian:"* ]]
  [[ "$output" != *"/cachebust:"* ]]
}

@test "ls supports filtering by tag" {
  run $APP ls :latest :7
  [[ "$output" == *":latest"* ]]
  [[ "$output" == *":7"* ]]
  [[ "$output" != *":nocache"* ]]
}

@test "ls supports filtering combination of repository, image, and tag" {
  run $APP ls test-repo/:latest
  [[ "$output" == *"test-repo/alpine:latest"* ]]
  [[ "$output" == *"test-repo/debian:latest"* ]]
  [[ "$output" != *"test-repo/debian:7"* ]]
  [[ "$output" != *"test-other/alpine:latest"* ]]
}

@test "ls supports pulling from requested source repositories" {
  run $APP ls --pull test-repo/
  [[ "$output" == *"pulling test-repo"* ]]
  [[ "$output" != *"pulling test-other"* ]]
}
