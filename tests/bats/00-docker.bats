#!/usr/bin/env bats

#
# 00 - dependencies
#

load helpers

@test "docker is running" {
  run docker ps -l
  echo $output
  [ $status -eq 0 ]
}

@test "docker can create and run a container" {
  run docker run --rm alpine:3.4 ls
  echo $output
  [ $status -eq 0 ]
}

@test "docker /tmp/dex-tests is aligned with host" {
  local target=$TMPDIR/docker-test

  mkdir -p $target/ping-pong
  run docker run --rm -v $target:/tmp alpine:3.4 ls /tmp
  rm -rf $target

  [ $status -eq 0 ]
  [ $output = "ping-pong" ]
}
