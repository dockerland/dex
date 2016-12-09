#!/usr/bin/env bats

#
# 50 - runtime command behavior
#

export DEX_NAMESPACE="dex/v1-tests"
load app

setup(){
  [ -e $APP ] || install_dex
  mk-imgtest
  mkdir -p $TMPDIR/label-test/{home,vol,workspace}
  __containers=()
  export TMPDIR=$TMPDIR
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
  rm -rf $TMPDIR/label-test
  rm_containers
}

@test "runtime properly sets \$HOME as /dex/home" {
  run $APP run imgtest/debian printenv HOME
  [ "$output" = "/dex/home" ]
}

@test "runtime properly sets cwd as /dex/workspace" {
  run $APP run imgtest/debian pwd
  [ "$output" = "/dex/workspace" ]
}

@test "runtime supports piping of stdin" {
  local out=$(echo "foo" | $APP run imgtest/debian sed 's/foo/bar/')
  [ $? -eq 0 ]
  [ "$out" = "bar" ]
}

@test "runtime assigns default v1 vars" {
  run $APP run imgtest/debian

  # v1 vars
  for line in ${lines[@]}; do echo $line ; done
  [[ $output == *"DEX_DOCKER_HOME=$DEX_HOME/homes/debian"* ]]
  [[ $output == *"DEX_DOCKER_WORKSPACE=$(pwd)"* ]]
  [[ $output == *"DEX_HOST_HOME=$HOME"* ]]
  [[ $output == *"DEX_HOST_PWD=$(pwd)"* ]]

  [[ $output == *"DEX_HOST_GID=$(id -g)"* ]]
  [[ $output == *"DEX_HOST_GROUP=$(id -gn)"* ]]
  [[ $output == *"DEX_HOST_UID=$(id -u)"* ]]
  [[ $output == *"DEX_HOST_USER=$(id -un)"* ]]

  [[ $output == *"DEX_IMAGE=$DEX_NAMESPACE/debian:latest"* ]]
  [[ $output == *"DEX_IMAGE_NAME=debian"* ]]
  [[ $output == *"DEX_IMAGE_TAG=latest"* ]]
}

@test "runtime assigns default passthrough vars" {
  # by default, LANG and TZ are passed-through to container
  export LANG="test"
  export TZ="test"

  run $APP run imgtest/debian

  # v1 passthrough
  [[ "$output" == *"LANG=test"* ]]
  [[ "$output" == *"TZ=test"* ]]
}

@test "runtime supports wildcard passthrough vars" {
  # by default, LANG and TZ are passed-through to container
  export LANG="test"
  export TZ="test"
  export TEST_A="test"
  export TEST_B="test"

  run $APP run imgtest/labels:passthru

  # v1 passthrough
  [[ "$output" == *"LANG=test"* ]]
  [[ "$output" == *"TZ=test"* ]]

  # wildcard passthrough
  [[ "$output" == *"TEST_A=test"* ]]
  [[ "$output" == *"TEST_B=test"* ]]
}

@test "runtime sets a unique home by default (DEX_HOME/homes/<image>-<tag>)" {
  rm -rf $DEX_HOME/homes/debian-latest

  run $APP run imgtest/debian:latest
  [ $status -eq 0 ]
  [ -d $DEX_HOME/homes/debian-latest ]
}

@test "runtime respects docker_envars label" {
  # imgtest/labels image ::
  # LABEL org.dockerland.dex.docker_envars="BATS_TESTVAR"

  export BATS_TESTVAR="abc"
  $APP run imgtest/labels printenv -0 BATS_TESTVAR
  [ "$($APP run imgtest/labels printenv -0 BATS_TESTVAR)" = "abc" ]
}

@test "runtime supports variable expansion in docker_home label" {
  # imgtest/labels image ::
  # LABEL org.dockerland.dex.docker_home="\$TMPDIR/label-test/home"
  mkdir -p $TMPDIR/label-test/home
  touch $TMPDIR/label-test/home/__exists__

  run $APP run --build imgtest/labels ls /dex/home/__exists__
  [ $status -eq 0 ]
}

@test "runtime expands ~ as real \$HOME in labels" {
  # imgtest/labels:home image ::
  # LABEL org.dockerland.dex.docker_home="~"
  # LABEL org.dockerland.dex.docker_volumes="~:/realhome:ro"
  touch $DEX_HOME/.dex_realhome_test

  HOME=$DEX_HOME $APP run --build imgtest/labels:home ls /dex/home/.dex_realhome_test
  HOME=$DEX_HOME $APP run imgtest/labels:home ls /realhome/.dex_realhome_test

  rm -rf $DEX_HOME/.dex_realhome_test
}

@test "runtime supports variable expansion in docker_workspace label" {
  # imgtest/labels image ::
  # LABEL org.dockerland.dex.docker_workspace="\$TMPDIR/label-test/workspace"
  touch $TMPDIR/label-test/workspace/__exists__

  run $APP run imgtest/labels ls __exists__
  [ $status -eq 0 ]
}

@test "runtime respects docker_flags label" {
  # imgtest/labels image ::
  # LABEL dockerland.dex.docker_flags="--tty -e TESTVAR=TEST"

  [ "$($APP run imgtest/labels printenv -0 TESTVAR)" = "TEST" ]
}

@test "runtime respects docker_groups label, maps to host group ID" {
  # imgtest/labels image ::
  # LABEL dockerland.dex.docker_groups="tty"

  host_gid=$($APP runfunc get/gid_from_name tty)
  found=false

  for gid in $($APP run imgtest/labels id -G); do
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
  run $APP run imgtest/debian ls /dev/tty0
  [ $status -eq 2 ]

  run $APP run imgtest/debian ls /dev/console
  [ $status -eq 2 ]

  run $APP run imgtest/labels ls /dev/tty0
  echo $output
  $APP run imgtest/labels ls /dev/
  [ $status -eq 0 ]

  run $APP run imgtest/labels ls /dev/console
  [ $status -eq 0 ]
}

@test "runtime respects docker_volumes label" {
  # imgtest/labels image ::
  # LABEL org.dockerland.dex.docker_volumes="\$TMPDIR/label-test/vol \$TMPDIR/label-test/vol:/tmp/ro:ro"
  touch $TMPDIR/label-test/vol/__exists__

  run $APP run imgtest/labels ls $TMPDIR/label-test/vol/__exists__
  [ $status -eq 0 ]

  run $APP run imgtest/labels ls /tmp/ro/__exists__
  [ $status -eq 0 ]

  run $APP run imgtest/labels rm /tmp/ro/__exists__
  [ $status -eq 1 ]
}

@test "runtime ro-mounts host paths to coax common absolute path resolutions" {
  cd $TMPDIR
  $APP run imgtest/debian ls $TMPDIR

  run $APP run imgtest/labels:disable-host_paths ls $TMPDIR
  [ $status -eq 2 ]
}

@test "runtime respects host_users label for ro-mounting of host users/groups" {
  run $APP run imgtest/debian whoami
  [ $status -eq 1 ]

  $APP image build imgtest/labels:enable-host_users
  run $APP run imgtest/labels:enable-host_users whoami
  for line in ${lines[@]}; do
    echo "$line"
  done
  [ $status -eq 0 ]
  [ "$output" = "$(id -un 2>/dev/null)" ]
}

@test "runtime respects host_docker label for passthrough of host docker socket and vars" {
  # test if host docker is [NOT!] exposed by default
  $APP run imgtest/debian [ -S /var/run/docker.sock ] && false

  # test if /var/run/docker.sock gets exposed when host_docker label is set
  $APP run imgtest/labels:enable-host_docker [ -S /var/run/docker.sock ]

  # test polling of host docker (default command outputs `docker info`)
  $APP run imgtest/labels:enable-host_docker | grep -q Plugins

  # test DOCKER_ envar passthrough
  run DOCKER_TEST="test" $APP run imgtest/labels:enable-host_docker printenv
  [[ $output == *"DOCKER_TEST=test"* ]]
}

@test "runtime suppresses tty flags when container output is piped" {
  # imgtest/labels image ::
  # LABEL dockerland.dex.docker_flags="--tty -e TESTVAR=TEST"
  local out=$(DEX_DEBUG=true $APP run imgtest/labels echo "foo" | sed 's/foo/bar/')
  [[ "$out" == *"--tty=false"* ]]

  local out=$($APP run imgtest/labels echo "foo" | sed 's/foo/bar/')
  [ "$out" = "bar" ]
}

@test "runtime suppresses tty flags when container input is piped" {
  # imgtest/labels image ::
  # LABEL dockerland.dex.docker_flags="--tty -e TESTVAR=TEST"
  local out=$(echo "foo" | DEX_DEBUG=true $APP run imgtest/labels sed 's/foo/bar/')
  [[ "$out" == *"--tty=false"* ]]

  local out=$(echo "foo" | $APP run imgtest/labels sed 's/foo/bar/')
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

  run $APP run imgtest/debian ls /dex/home/
  [ "$output" = "ping-pong" ]

  run $APP run imgtest/debian ls
  [ "$output" = "deux" ]


  export DEX_DOCKER_ENTRYPOINT=/bin/echo
  export DEX_DOCKER_CMD="entrypoint-cmd-test"
  run $APP run imgtest/debian
  [ "$output" = "entrypoint-cmd-test" ]


  # persist a container so we can inspect it.
  get_containers
  [ ${#__containers[@]} -eq 0 ]

  export DEX_DOCKER_UID=$(id root -u)
  export DEX_DOCKER_GID=$(id root -g)
  export DEX_DOCKER_LOG_DRIVER="json-file"

  run $APP run --persist imgtest/debian
  [ $status -eq 0 ]

  get_containers
  [ ${#__containers[@]} -eq 1 ]
  [ $(docker inspect --format "{{ index .Config \"User\" }}" ${__containers[0]}) = "$DEX_DOCKER_UID:$DEX_DOCKER_GID" ]
  [ $(docker inspect --format "{{ index .HostConfig.LogConfig \"Type\" }}" ${__containers[0]}) = "$DEX_DOCKER_LOG_DRIVER" ]
}

@test "runtime respects window label and DEX_WINDOW_FLAGS envar" {
  (
    export DEX_WINDOW_FLAGS="-e WINDOW_FLAG=abc"
    [ "$($APP run imgtest/labels:x11 printenv -0 WINDOW_FLAG)" = "abc" ]
    [ "$($APP run imgtest/labels:x11 printenv -0 DEX_WINDOW)" = "true" ]
  ) || return 1
}

@test "runtime always targets local/default docker host" {
  get_containers
  [ ${#__containers[@]} -eq 0 ]

  echo "mock setting DOCKER_HOST"
  (
    set -e
    export DOCKER_HOST=an.invalid-host.tld
    export DOCKER_MACHINE_NAME=invalid-host

    run $APP run --persist imgtest/debian
    [ $status -eq 0 ]
  )

  get_containers
  [ ${#__containers[@]} -eq 1 ]
}
