#!/usr/bin/env bats

#
# 00 - test dependencies
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

@test "docker ensure \$TMPDIR in container is aligned with host" {
  rm -rf $TMPDIR/docker-test && mkdir -p $TMPDIR/docker-test/ping-pong
  run docker run --rm -v $TMPDIR/docker-test/:/tmp alpine:3.4 ls /tmp
  echo $TMPDIR

  [ $status -eq 0 ]
  [ "$output" = "ping-pong" ]
}
