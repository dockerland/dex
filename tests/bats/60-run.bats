#!/usr/bin/env bats

#
# 60 - runtime command behavior
#

load app

setup(){
  make/test-repo
}

@test "run errexits if unable to find image in repo checkouts" {
  run $APP run test-repo/certainly-missing
  [[ "$output" == *"test-repo/certainly-missing:latest is missing"* ]]
  [ $status -eq 1 ]
  # ^^^ exit 1 is important as we use assume in subsequent tests
}

@test "run automatically builds (and runs) image" {
  $APP image rm --force test-repo/debian
  run $APP run test-repo/debian
  [ $status -eq 0 ]
  [[ $output == *"building"* ]]
  [[ $output == *"DEBIAN_RELEASE"* ]]
}

@test "run supports pulling from source(s)" {
  $APP image rm --force test-repo/debian
  app/var __checkouts
  rm -rf $__checkouts/test-repo
  run $APP run test-repo/debian
  [ $status -eq 1 ]
  run $APP run --pull test-repo/debian
  [ $status -eq 0 ]
}

@test "run --persist keeps containers around after they exit" {
  for container in $($APP ps -q test-repo/debian); do
    [[ "$(docker/find/labels $container)" == *"$DEX_NAMESPACE"* ]] && \
      docker/local rm --force $container
  done

  $APP ps -q test-repo/debian
  $APP run test-repo/debian
  [ -z "$($APP ps -q test-repo/debian)" ]

  $APP run --persist test-repo/debian
  [ -n "$($APP ps -q test-repo/debian)" ]
}


@test "run passes arguments through to container" {
  run $APP run test-repo/debian echo 'ping-pong'
  [ $status -eq 0 ]
  [ $output = "ping-pong" ]
}

@test "run returns exit code from container's command" {
  run $APP run test-repo/debian ls /no-dang-way
  [ $status -eq 2 ]
}

@test "run allows passing alternative CMD and entrypoint" {
  run $APP run --entrypoint "echo" --cmd "ping-pong" test-repo/debian
  [ $status -eq 0 ]
  [ $output = "ping-pong" ]
}

@test "run allows passing alternative UID and GID" {
  [ $($APP run --uid 1 test-repo/debian id -u) -eq 1 ]
  [ $($APP run --gid 1 test-repo/debian id -g) -eq 1 ]
}

@test "run allows passing alternative HOME and CWD" {
  rm -rf $TMPDIR/alt-home/ ; mkdir -p $TMPDIR/alt-home/abc
  [ $($APP run --workspace $TMPDIR/alt-home/ test-repo/debian ls) = "abc" ]
  [ $($APP run --home $TMPDIR/alt-home/ test-repo/debian ls /dex/home) = "abc" ]
}

@test "run allows passing alternative log-driver" {
  for container in $($APP ps -q test-repo/debian); do
    name="$(docker/get/repotag $container)" || true
    [[ "$name" == "$DEX_NAMESPACE"* ]] && \
      docker/local rm --force $container
  done

  run $APP run --persist --log-driver json-file test-repo/debian
  container=$($APP ps -q test-repo/debian | head -n1)
  [ $(docker inspect --format "{{ index .HostConfig.LogConfig \"Type\" }}" $container) = "json-file" ]
}
