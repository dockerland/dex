#!/usr/bin/env bats

#
# 07 - runtime
#

load dex

export DEX_NAMESPACE="dex/v1-tests"

setup(){
  [ -e $DEX ] || install_dex
  mk-images
}

teardown(){
  rm -rf $TMPDIR/docker-test
}

@test "run errors if it cannot find an image" {
  run $DEX run imgtest/certainly-missing
  [ $status -eq 1 ]
}

@test "run automatically builds (and runs) image" {
  run $DEX image --force rm imgtest/*
  run $DEX run imgtest/debian
  echo $output
  [ $status -eq 0 ]
  [[ $output == *"built imgtest/debian"* ]]
  [[ $output == *"DEBIAN_RELEASE"* ]]
}

@test "run supports passing of arguments to container's command" {
  run $DEX run imgtest/debian echo 'ping-pong'
  [ $status -eq 0 ]
  [ $output = "ping-pong" ]
}

@test "run properly sets \$HOME as /dex/home" {
  run $DEX run imgtest/debian printenv HOME
  [ $output = "/dex/home" ]

  export DEX_DOCKER_HOME=$TMPDIR/docker-test
  mkdir -p $DEX_DOCKER_HOME/ping-pong

  run $DEX run imgtest/debian ls /dex/home/
  [ "$output" = "ping-pong" ]
}

@test "run properly sets cwd as /dex/workspace" {
  run $DEX run imgtest/debian pwd
  [ $output = "/dex/workspace" ]

  export DEX_DOCKER_WORKSPACE=$TMPDIR/docker-test
  mkdir -p $DEX_DOCKER_WORKSPACE/ping-pong

  run $DEX run imgtest/debian ls
  [ "$output" = "ping-pong" ]
}

@test "run supports piping of stdin" {
  local out=$(echo "foo" | $DEX run imgtest/debian sed 's/foo/bar/')
  [ $? -eq 0 ]
  [ "$out" = "bar" ]
}
