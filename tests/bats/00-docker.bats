#!/usr/bin/env bats

#
# 00 - dependencies
#

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
