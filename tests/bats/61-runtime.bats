#!/usr/bin/env bats

#
# 60 - runtime command behavior
#

load app

setup(){
  make/test-repo

  # lebel helpers...
  mkdir -p $TMPDIR/label-test/{home,vol,workspace}
  export TMPDIR="$TMPDIR"

  # clean any running containers
  local id
  for id in $($APP ps -q test-repo/); do
    docker rm --force $id
  done
}

teardown(){
  unset DOCKER_HOST
  unset DOCKER_MACHINE_NAME
}

@test "runtime properly sets \$HOME as /dex/home" {
  run $APP run test-repo/debian printenv HOME
  [ "$output" = "/dex/home" ]
}

@test "runtime properly sets cwd as /dex/workspace" {
  run $APP run test-repo/debian pwd
  [ "$output" = "/dex/workspace" ]
}

@test "runtime supports piping of stdin" {
  #@TODO this should be a test of "installed" script
  [ "$(echo "foo" | $APP run test-repo/debian sed 's/foo/bar/')" = "bar" ]
}

@test "runtime assigns default v1 vars" {
  run $APP run test-repo/debian

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

  [[ $output == *"DEX_IMAGE=$DEX_NAMESPACE/test-repo/debian:latest"* ]]
  [[ $output == *"DEX_IMAGE_NAME=debian"* ]]
  [[ $output == *"DEX_IMAGE_TAG=latest"* ]]
}

@test "runtime assigns default passthrough vars" {
  # by default, LANG and TZ are passed-through to container
  export LANG="test"
  export TZ="test"

  run $APP run test-repo/debian

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

  run $APP run test-repo/labels:passthru

  # v1 passthrough
  [[ "$output" == *"LANG=test"* ]]
  [[ "$output" == *"TZ=test"* ]]

  # wildcard passthrough
  [[ "$output" == *"TEST_A=test"* ]]
  [[ "$output" == *"TEST_B=test"* ]]
}

@test "runtime sets a unique home by default (DEX_HOME/homes/<image>-<tag>)" {
  rm -rf $DEX_HOME/homes/debian-latest

  run $APP run test-repo/debian:latest
  [ $status -eq 0 ]
  [ -d $DEX_HOME/homes/debian-latest ]
}

@test "runtime respects docker_envars label" {
  # test-repo/labels image ::
  # LABEL org.dockerland.dex.docker_envars="BATS_TESTVAR"

  export BATS_TESTVAR="abc"
  $APP run test-repo/labels printenv -0 BATS_TESTVAR
  [ "$($APP run test-repo/labels printenv -0 BATS_TESTVAR)" = "abc" ]
}

@test "runtime supports variable expansion in docker_home label" {
  # test-repo/labels image ::
  # LABEL org.dockerland.dex.docker_home="\$TMPDIR/label-test/home"
  mkdir -p $TMPDIR/label-test/home
  touch $TMPDIR/label-test/home/__exists__

  run $APP run --build test-repo/labels ls /dex/home/__exists__
  [ $status -eq 0 ]
}

@test "runtime expands ~ as real \$HOME in labels" {
  # test-repo/labels:home image ::
  # LABEL org.dockerland.dex.docker_home="~"
  # LABEL org.dockerland.dex.docker_volumes="~:/realhome:ro"
  touch $DEX_HOME/.dex_realhome_test

  HOME=$DEX_HOME $APP run --build test-repo/labels:home ls /dex/home/.dex_realhome_test
  HOME=$DEX_HOME $APP run test-repo/labels:home ls /realhome/.dex_realhome_test

  rm -rf $DEX_HOME/.dex_realhome_test
}

@test "runtime supports variable expansion in docker_workspace label" {
  # test-repo/labels image ::
  # LABEL org.dockerland.dex.docker_workspace="\$TMPDIR/label-test/workspace"
  touch $TMPDIR/label-test/workspace/__exists__

  run $APP run test-repo/labels ls __exists__
  [ $status -eq 0 ]
}

@test "runtime respects docker_flags label" {
  # test-repo/labels image ::
  # LABEL dockerland.dex.docker_flags="--tty -e TESTVAR=TEST"

  [ "$($APP run test-repo/labels printenv -0 TESTVAR)" = "TEST" ]
}

@test "runtime respects docker_groups label, maps to host group ID" {
  # test-repo/labels image ::
  # LABEL dockerland.dex.docker_groups="tty"

  host_gid=$($APP runfunc get/gid_from_name tty)
  found=false

  for gid in $($APP run test-repo/labels id -G); do
    # trim trailing null character
    gid=$(echo $gid | io/trim)
    echo "comparing container gid: $gid to host gid: $host_gid"
    if [ $gid = "$host_gid" ]; then
      found=true
      break
    fi
  done

  $found
}

@test "runtime respects docker_devices label" {
  # test-repo/labels image ::
  # LABEL org.dockerland.dex.docker_devices="tty0 /dev/console"
  run $APP run test-repo/debian ls /dev/tty0
  [ $status -eq 2 ]

  run $APP run test-repo/debian ls /dev/console
  [ $status -eq 2 ]

  run $APP run test-repo/labels ls /dev/tty0
  echo $output
  $APP run test-repo/labels ls /dev/
  [ $status -eq 0 ]

  run $APP run test-repo/labels ls /dev/console
  [ $status -eq 0 ]
}

@test "runtime respects docker_volumes label" {
  # test-repo/labels image ::
  # LABEL org.dockerland.dex.docker_volumes="\$TMPDIR/label-test/vol \$TMPDIR/label-test/vol:/tmp/ro:ro"
  touch $TMPDIR/label-test/vol/__exists__

  run $APP run test-repo/labels ls $TMPDIR/label-test/vol/__exists__
  [ $status -eq 0 ]

  run $APP run test-repo/labels ls /tmp/ro/__exists__
  [ $status -eq 0 ]

  run $APP run test-repo/labels rm /tmp/ro/__exists__
  [ $status -eq 1 ]
}

@test "runtime ro-mounts host paths to coax common absolute path resolutions" {
  cd $TMPDIR
  $APP run test-repo/debian ls $TMPDIR

  run $APP run test-repo/labels:disable-host_paths ls $TMPDIR
  [ $status -eq 2 ]
}

@test "runtime host_users label triggers creation of reference container and files" {
  dir=$($APP runfunc dex/get/reference-path $DEX_NAMESPACE/test-repo/labels:enable-host_users)
  [[ "$dir" == "$DEX_HOME/references/"* ]]

  rm -rf $dir
  run $APP image build test-repo/labels:enable-host_users
  run $APP run test-repo/labels:enable-host_users
  [ -d "$dir" ]
  [ -e "$dir/passwd" ]
  [ -e "$dir/group" ]
}

@test "runtime respects host_users label for ro-mounting of host users/groups" {
  run $APP run test-repo/debian whoami
  [ $status -eq 1 ]

  run $APP run test-repo/labels:enable-host_users whoami
  [ $status -eq 0 ]
  [ "$output" = "$(id -un 2>/dev/null)" ]
}

@test "runtime respects host_docker label for passthrough of host docker socket and vars" {
  # test if host docker is [NOT!] exposed by default
  $APP run test-repo/debian [ -S /var/run/docker.sock ] && false

  # test if /var/run/docker.sock gets exposed when host_docker label is set
  $APP run test-repo/labels:enable-host_docker [ -S /var/run/docker.sock ]

  # test polling of host docker (default command outputs `docker info`)
  $APP run test-repo/labels:enable-host_docker | grep -q Plugins

  # test DOCKER_ envar passthrough
  run DOCKER_TEST="test" $APP run test-repo/labels:enable-host_docker printenv
  [[ $output == *"DOCKER_TEST=test"* ]]
}

@test "runtime suppresses tty flags when container output is piped" {
  # test-repo/labels image ::
  # LABEL dockerland.dex.docker_flags="--tty -e TESTVAR=TEST"
  local out=$(DEX_DEBUG=true $APP run test-repo/labels echo "foo" | sed 's/foo/bar/')
  [[ "$out" == *"--tty=false"* ]]

  local out=$($APP run test-repo/labels echo "foo" | sed 's/foo/bar/')
  [ "$out" = "bar" ]
}

@test "runtime suppresses tty flags when container input is piped" {
  # test-repo/labels image ::
  # LABEL dockerland.dex.docker_flags="--tty -e TESTVAR=TEST"
  local out=$(echo "foo" | DEX_DEBUG=true $APP run test-repo/labels sed 's/foo/bar/')
  [[ "$out" == *"--tty=false"* ]]

  local out=$(echo "foo" | $APP run test-repo/labels sed 's/foo/bar/')
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

  run $APP run test-repo/debian ls /dex/home/
  [ "$output" = "ping-pong" ]

  run $APP run test-repo/debian ls
  [ "$output" = "deux" ]


  export DEX_DOCKER_ENTRYPOINT=/bin/echo
  export DEX_DOCKER_CMD="entrypoint-cmd-test"
  run $APP run test-repo/debian
  [ "$output" = "entrypoint-cmd-test" ]


  # persist a container so we can inspect it.
  export DEX_DOCKER_UID=$(id root -u)
  export DEX_DOCKER_GID=$(id root -g)
  export DEX_DOCKER_LOG_DRIVER="json-file"


  run $APP run --persist test-repo/debian
  local id=$($APP ps -q test-repo/debian)
  [ -n "$id" ]
  [ $(docker inspect --format "{{ index .Config \"User\" }}" $id) = "$DEX_DOCKER_UID:$DEX_DOCKER_GID" ]
  [ $(docker inspect --format "{{ index .HostConfig.LogConfig \"Type\" }}" $id) = "$DEX_DOCKER_LOG_DRIVER" ]
}

@test "runtime respects window label and DEX_WINDOW_FLAGS envar" {
  (
    export DEX_WINDOW_FLAGS="-e WINDOW_FLAG=abc"
    [ "$($APP run test-repo/labels:x11 printenv -0 WINDOW_FLAG)" = "abc" ]
    [ "$($APP run test-repo/labels:x11 printenv -0 DEX_WINDOW)" = "true" ]
  ) || return 1
}

@test "runtime always targets local/default docker host" {
  export DOCKER_HOST=an.invalid-host.tld
  export DOCKER_MACHINE_NAME=invalid-host

  run docker/local ps -aq --filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE
  [ ${#lines[@]} -eq 0 ]

  run $APP run --persist test-repo/debian
  run docker/local ps -aq --filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE
  [ ${#lines[@]} -eq 1 ]
}
