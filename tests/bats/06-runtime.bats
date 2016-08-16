#!/usr/bin/env bats

#
# 07 - runtime
#

export DEX_NAMESPACE="dex/v1-tests"
load dex


setup(){
  [ -e $DEX ] || install_dex
  mk-images
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

@test "runtime environmental variables override behavior" {

  # DEX_DOCKER_HOME - docker host directory mounted as the container's $HOME
  # DEX_DOCKER_WORKSPACE - docker host directory mounted as the container's CWD
  # DEX_DOCKER_FLAGS - flags passed to docker run
  # DEX_DOCKER_ENTRYPOINT - alternative entrypoint passed to docker run
  # DEX_DOCKER_CMD - alternative command passed to docker run
  # DEX_DOCKER_UID - uid to run the container under
  # DEX_DOCKER_GID - gid to run the container under
  # DEX_DOCKER_LOG_DRIVER - logging driver to use for container
  # DEX_DOCKER_PERSIST - when false, container is removed after it exits

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

  export DEX_DOCKER_PERSIST=true
  export DEX_DOCKER_UID=$(id root -u)
  export DEX_DOCKER_GID=$(id root -g)
  export DEX_DOCKER_LOG_DRIVER="json-file"
  export DEX_DOCKER_FLAGS="--label=org.dockerland.dex.runtime-test=ping-pong"

  run $DEX run imgtest/debian
  [ $status -eq 0 ]

  get_containers
  [ ${#__containers[@]} -eq 1 ]
  [ $(docker inspect --format "{{ index .Config \"User\" }}" ${__containers[0]}) = "$DEX_DOCKER_UID:$DEX_DOCKER_GID" ]
  [ $(docker inspect --format "{{ index .HostConfig.LogConfig \"Type\" }}" ${__containers[0]}) = "$DEX_DOCKER_LOG_DRIVER" ]
  [ $(docker inspect --format "{{ index .Config.Labels \"org.dockerland.dex.runtime-test\" }}" ${__containers[0]}) = "ping-pong" ]
}

#@TODO test X11 flags/containers
