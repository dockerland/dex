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
}

teardown(){
  docker/local rm --force $name
}

@test "ps lists running containers, resembers docker ps" {
  [ -z "$($APP ps -q)" ]
  docker/local run --name=$name $DEX_NAMESPACE/test-repo/alpine:latest
  [ -n "$($APP ps -q)" ]
  diff <($APP ps -q) <(docker/local ps -aq --filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE)
  diff <($APP ps) <(docker/local ps -a --filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE)
}

@test "ps -a lists containers across reuntimes" {
  docker/local run --name=$name --label=org.dockerland.dex.namespace=ps_bats_test $DEX_NAMESPACE/test-repo/alpine:latest
  [ -z "$($APP ps -q)" ]

  run $APP ps -a
  [[ "$output" == *"$name"* ]]
}
