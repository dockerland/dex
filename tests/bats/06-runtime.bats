#!/usr/bin/env bats

#
# 07 - runtime
#

export DEX_NAMESPACE="dex/v1-tests"
load dex


setup(){
  [ -e $DEX ] || install_dex
  mk-images
    mkdir -p /tmp/dex-tests/tmp/{home,workspace,vol}
  __containers=()
}

get_containers(){
  __containers=()
  local filters="--filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE"
  for container in $(docker ps -aq $filters); do
    __containers+=( $container )
  done
}

rm_containers(){
  get_containers
  for container in ${__containers[@]}; do
    docker rm --force $container
  done
}

teardown(){
  rm -rf $TMPDIR/docker-test
  rm_containers
}


@test "runtime properly sets \$HOME as /dex/home" {
  run $DEX run imgtest/debian printenv HOME
  [ $output = "/dex/home" ]
}

@test "runtime properly sets cwd as /dex/workspace" {
  run $DEX run imgtest/debian pwd
  [ $output = "/dex/workspace" ]
}

@test "runtime supports piping of stdin" {
  local out=$(echo "foo" | $DEX run imgtest/debian sed 's/foo/bar/')
  [ $? -eq 0 ]
  [ "$out" = "bar" ]
}

@test "runtime assigns default v1 vars + envar passthu" {
  export LANG="test"
  export TZ="test"

  run $DEX run imgtest/debian

  # v1 vars
  for line in ${lines[@]}; do echo $line ; done
  [[ $output == *"DEX_API=v1"* ]]
  [[ $output == *"DEX_DOCKER_HOME=/tmp/dex-tests/home"* ]]
  [[ $output == *"DEX_DOCKER_WORKSPACE=$(pwd)"* ]]
  [[ $output == *"DEX_HOST_HOME=$HOME"* ]]
  [[ $output == *"DEX_HOST_PWD=$(pwd)"* ]]

  # v1 passthrough
  [[ $output == *"LANG=test"* ]]
  [[ $output == *"TZ=test"* ]]
}

@test "runtime respects docker_envars label" {
  # imgtest/labels image ::
  # LABEL org.dockerland.dex.docker_envars="BATS_TESTVAR"

  export BATS_TESTVAR="abc"
  [ "$($DEX run imgtest/labels printenv -0 BATS_TESTVAR)" = "abc" ]
}

@test "runtime respects docker_home label" {
  # imgtest/labels image ::
  # LABEL org.dockerland.dex.docker_home="/tmp/dex-tests/tmp/home"
  touch /tmp/dex-tests/tmp/home/__exists__

  run $DEX run imgtest/labels ls /dex/home/__exists__
  [ $status -eq 0 ]
}

@test "runtime respects docker_workspace label" {
  # imgtest/labels image ::
  # LABEL org.dockerland.dex.docker_workspace="/tmp/dex-tests/tmp/workspace"
  touch /tmp/dex-tests/tmp/workspace/__exists__

  run $DEX run imgtest/labels ls __exists__
  [ $status -eq 0 ]
}

@test "runtime respects docker_flags label" {
  # imgtest/labels image ::
  # LABEL dockerland.dex.docker_flags="--tty -e TESTVAR=TEST"

  [ "$($DEX run imgtest/labels printenv -0 TESTVAR)" = "TEST" ]
}

@test "runtime respects docker_groups label, maps to host group ID" {
  # imgtest/labels image ::
  # LABEL dockerland.dex.docker_groups="tty"

  host_gid=$(getent group tty | cut -d: -f3)
  found=false

  for gid in $($DEX run imgtest/labels id -G); do
    # trim trailing null character
    gid=$(echo $gid | tr -d '[:space:]')
    echo "comparing container gid: $gid to host gid: $host_gid"
    if [ $gid = "$host_gid" ]; then
      found=true
      break
    fi
  done

  $found
}

@test "runtime respects docker_devices label" {
  # imgtest/labels image ::
  # LABEL org.dockerland.dex.docker_devices="tty0 /dev/console"
  run $DEX run imgtest/debian ls /dev/tty0
  [ $status -eq 2 ]

  run $DEX run imgtest/debian ls /dev/console
  [ $status -eq 2 ]

  run $DEX run imgtest/labels ls /dev/tty0
  echo $output
  $DEX run imgtest/labels ls /dev/
  [ $status -eq 0 ]

  run $DEX run imgtest/labels ls /dev/console
  [ $status -eq 0 ]
}

@test "runtime respects docker_volumes label" {
  # imgtest/labels image ::
  # LABEL org.dockerland.dex.docker_volumes="/tmp/dex-tests/tmp/vol /tmp/dex-tests/tmp/vol-ro:/tmp/ro:ro"
  touch /tmp/dex-tests/tmp/vol/__exists__

  run $DEX run imgtest/labels ls /tmp/dex-tests/tmp/vol/__exists__
  [ $status -eq 0 ]

  run $DEX run imgtest/labels ls /tmp/ro/__exists__
  echo $output
  [ $status -eq 0 ]

  run $DEX run imgtest/labels rm /tmp/ro/__exists__
  [ $status -eq 1 ]
}

@test "runtime suppresses tty flags when stdin is piped" {
  # imgtest/labels image ::
  # LABEL dockerland.dex.docker_flags="--tty -e TESTVAR=TEST"
  local out=$(echo "foo" | $DEX run imgtest/labels sed 's/foo/bar/')
  [ $? -eq 0 ]
  [ "$out" = "bar" ]
}

@test "runtime environmental variables override behavior" {

  # DEX_DOCKER_HOME - docker host directory mounted as the container's $HOME
  # DEX_DOCKER_WORKSPACE - docker host directory mounted as the container's CWD
  # DEX_DOCKER_FLAGS - flags passed to docker run
  # DEX_DOCKER_ENTRYPOINT - alternative entrypoint passed to docker run
  # DEX_DOCKER_CMD - alternative command passed to docker run
  # DEX_DOCKER_UID - uid to run the container under
  # DEX_DOCKER_GID - gid to run the container under
  # DEX_DOCKER_LOG_DRIVER - logging driver to use for container

  export DEX_DOCKER_HOME=$TMPDIR/docker-test
  export DEX_DOCKER_WORKSPACE=$DEX_DOCKER_HOME/ping-pong
  mkdir -p $DEX_DOCKER_HOME/ping-pong/deux

  run $DEX run imgtest/debian ls /dex/home/
  [ "$output" = "ping-pong" ]

  run $DEX run imgtest/debian ls
  [ "$output" = "deux" ]


  export DEX_DOCKER_ENTRYPOINT=/bin/echo
  export DEX_DOCKER_CMD="entrypoint-cmd-test"
  run $DEX run imgtest/debian
  [ "$output" = "entrypoint-cmd-test" ]


  # persist a container so we can inspect it.
  get_containers
  [ ${#__containers[@]} -eq 0 ]

  export DEX_DOCKER_UID=$(id root -u)
  export DEX_DOCKER_GID=$(id root -g)
  export DEX_DOCKER_LOG_DRIVER="json-file"

  run $DEX run --persist imgtest/debian
  [ $status -eq 0 ]

  get_containers
  [ ${#__containers[@]} -eq 1 ]
  [ $(docker inspect --format "{{ index .Config \"User\" }}" ${__containers[0]}) = "$DEX_DOCKER_UID:$DEX_DOCKER_GID" ]
  [ $(docker inspect --format "{{ index .HostConfig.LogConfig \"Type\" }}" ${__containers[0]}) = "$DEX_DOCKER_LOG_DRIVER" ]
}

#@TODO test X11 flags/containers
