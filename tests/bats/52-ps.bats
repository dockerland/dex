#!/usr/bin/env bats

#
# 50 - command behavior
#

load app

setup(){
  make/test-repo
  [ -n "$(docker/local images -q $DEX_NAMESPACE/test-repo/alpine:latest)" ] || \
    $APP image build test-repo/alpine:latest
  export name=$(docker/get/safe-name "$DEX_NAMESPACE" "ps_bats_test")
  docker/local rm --force $name || true
  docker/local rm --force ${name}debian || true
}

teardown(){
  docker/local rm --force $name || true
  docker/local rm --force ${name}debian || true
}

@test "ps lists running containers, resembers docker ps" {
  [ -z "$($APP ps -q)" ]
  docker/local run --name=$name $DEX_NAMESPACE/test-repo/alpine:latest
  [ -n "$($APP ps -q)" ]
  diff <($APP ps -q) <(docker/local ps -aq --filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE)
  diff <($APP ps) <(docker/local ps -a --filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE)
}

@test "ps -a lists containers across runtimes" {
  docker/local run --name=$name --label=org.dockerland.dex.namespace=ps_bats_test $DEX_NAMESPACE/test-repo/alpine:latest
  [ -z "$($APP ps -q)" ]

  run $APP ps -a
  [[ "$output" == *"$name"* ]]
}

@test "ps supports repotag" {
  cat $DEX_HOME/sources.list
  $APP image build --pull test-repo/debian:8

  docker/local run --name=$name $DEX_NAMESPACE/test-repo/alpine:latest
  docker/local run --name=${name}debian $DEX_NAMESPACE/test-repo/debian:8

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
