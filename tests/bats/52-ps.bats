#!/usr/bin/env bats

#
# 50 - command behavior
#

load app

setup(){
  make/test-repo
  [ -n "$(docker/local images -q $DEX_NAMESPACE/test-repo/alpine:latest)" ] || \
    $APP image build test-repo/alpine:latest
  remove_containers
}

teardown(){
  remove_containers
}

remove_containers(){
  for c in $(docker/local ps -aq --filter label=org.dockerland.dex.namespace=$DEX_NAMESPACE); do
    docker rm --force $c
  done
}

@test "ps lists running containers" {
  [ -z "$($APP ps -q)" ]
  docker/local run $DEX_NAMESPACE/test-repo/alpine:latest
  [ -n "$($APP ps -q)" ]
}

@test "ps output resembles docker ps command" {
  docker/local run $DEX_NAMESPACE/test-repo/alpine:latest
  diff <($APP ps -q) <(docker/local ps -aq --filter label=org.dockerland.dex.namespace=$DEX_NAMESPACE)
  diff <($APP ps --format "{{.Repository}}") <(docker/local ps -a --format "{{.Repository}}" --filter label=org.dockerland.dex.namespace=$DEX_NAMESPACE)
}

@test "ps -a lists containers across runtimes" {
  docker/local run --label=org.dockerland.dex.namespace=ps_bats_test $DEX_NAMESPACE/test-repo/alpine:latest
  [ -z "$($APP ps -q)" ]

  run $APP ps -a
  [[ "$output" == *"$name"* ]]
}

@test "ps supports repotag" {
  cat $DEX_HOME/sources.list
  $APP image build --pull test-repo/debian:8

  docker/local run $DEX_NAMESPACE/test-repo/alpine:latest
  docker/local run $DEX_NAMESPACE/test-repo/debian:8

  run $APP ps -q
  [ ${#lines[@]} -eq 2 ]

  run $APP ps -q test-repo/
  [ ${#lines[@]} -eq 2 ]

  run $APP ps -q debian
  [ ${#lines[@]} -eq 1 ]

  run $APP ps -q :8
  [ ${#lines[@]} -eq 1 ]

  run $APP ps -q debian:8
  [ ${#lines[@]} -eq 1 ]

  run $APP ps -q test-repo/debian:8
  [ ${#lines[@]} -eq 1 ]
}
