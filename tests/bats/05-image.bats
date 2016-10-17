#!/usr/bin/env bats

#
# 06 - runtime
#

#@TODO test build --pull
#@TODO test building packages
#@TODO betters tests

load dex

export DEX_NAMESPACE="dex/v1-tests"

setup(){
  [ -e $DEX ] || install_dex
  mk-imgtest
}

@test "image build creates an image from checkouts" {
  [ -d $DEX_HOME/checkouts/imgtest/dex-images ]

  rm-images
  run $DEX image build imgtest/alpine
  [ $status -eq 0 ]

  run docker images -q $DEX_NAMESPACE/alpine:latest
  [ $status -eq 0 ]
  [ ${#lines[@]} -eq 1 ]
}

@test "image build labels images according to the current DEX_RUNTIME" {

  local img=$(docker images -q $DEX_NAMESPACE/alpine:latest)
  local api_version=$($DEX vars DEX_RUNTIME | sed 's/DEX_RUNTIME=//')

  [ ! -z "$img" ]
  [ ! -z "$api_version" ]

  echo "IMAGE: $img"

  for label in api build-api build-imgstr build-tag image namespace source; do

    val=$(docker inspect --format "{{ index .Config.Labels \"org.dockerland.dex.$label\" }}" $img)
    echo "$label=$val"

    case $label in
      api) [ "$val" = "$api_version" ];;
      build-*) [ -z "$val" ] && echo "$label is not set" && false ;;
      image) [ "$val" = "alpine" ] ;;
      namespace) [ "$val" = "$DEX_NAMESPACE" ] ;;
      source) [ "$val" = "imgtest" ] ;;
      *) echo "unknown label - $label" && false ;;
    esac
  done
}

@test "image build uses docker build cache" {

  # apparently docker applies `docker build --label X --label Y` in random order
  # @TODO file bug
  skip

  run $DEX image build imgtest/cachebust:cache
  [ $status -eq 0 ]
  echo $output
  first_sha=$(docker inspect -f '{{ .Id }}' $DEX_NAMESPACE/cachebust:cache)


  run $DEX image build imgtest/cachebust:cache
  [ $status -eq 0 ]
  echo $output
  second_sha=$(docker inspect -f '{{ .Id }}' $DEX_NAMESPACE/cachebust:cache)

  [ "$first_sha" = "$second_sha" ]
}

@test "image build uses CACHE_BUST argument to circumvent docker build cache" {
  run $DEX image build imgtest/cachebust:nocache
  [ $status -eq 0 ]
  first_sha=$(docker inspect -f '{{ .Id }}' $DEX_NAMESPACE/cachebust:nocache)

  run $DEX image build imgtest/cachebust:nocache
  [ $status -eq 0 ]
  second_sha=$(docker inspect -f '{{ .Id }}' $DEX_NAMESPACE/cachebust:nocache)

  [ "$first_sha" != "$second_sha" ]
}

@test "image ls prints built images in 'docker images' format" {
  run $DEX image ls
  [ "$(echo ${lines[0]} | awk '{print $1}')" = "$(docker images $IMAGES_FILTER | head -n1 | awk '{print $1}')" ]
  [[ "$output" == *"$DEX_NAMESPACE/alpine"* ]]
}

@test "image ls supports quiet flag akin to 'docker images -q'" {
  run $DEX image ls -q
  [ ! "$(echo ${lines[0]} | awk '{print $1}')" = "$(docker images $IMAGES_FILTER | head -n1 | awk '{print $1}')" ]
  [[ ! "$output" == *"$DEX_NAMESPACE/alpine"* ]]
  [ "${lines[0]}" = "$(docker images -q $IMAGES_FILTER | head -n1)" ]
}


@test "image rm errors if it cannot find images to remove" {
  run $DEX image rm imgtest/zzz
  [ $status -eq 1 ]
}

@test "image rm removes named image(s)" {
  run docker images -q $DEX_NAMESPACE/alpine:latest
  [ $status -eq 0 ]
  [ ${#lines[@]} -eq 1 ]

  run $DEX image rm imgtest/alpine
  run docker images -q $DEX_NAMESPACE/alpine:latest
  [ $status -eq 0 ]
  [ ${#lines[@]} -eq 0 ]
}


@test "image build respects tags" {
  [ -d $DEX_HOME/checkouts/imgtest/dex-images ]

  rm-images
  $DEX image build imgtest/alpine:3.2
  $DEX image build imgtest/alpine:edge

  run docker images -q $IMAGES_FILTER --filter=label=org.dockerland.dex.image=alpine
  echo $output
  [ ${#lines[@]} -eq 2 ]
}

@test "image build respects repo wildcards" {
  [ -d $DEX_HOME/checkouts/imgtest/dex-images ]

  rm-images
  $DEX image build imgtest/*

  local repo_image_count=$(ls -ld $DEX_HOME/checkouts/imgtest/dex-images/* | wc -l)
  run docker images -q $IMAGES_FILTER
  [ ${#lines[@]} -eq $repo_image_count ]
}

@test "image rm respects repo wildcards" {
  local image_count=$(docker images -q $IMAGES_FILTER | wc -l)
  [ $image_count -ne 0 ]

  run $DEX image rm imgtest/*
  [ $status -eq 0 ]

  image_count=$(docker images -q $IMAGES_FILTER | wc -l)
  [ $image_count -eq 0 ]
}

@test "image build|ls|rm always target local/default docker host" {
  rm-images

  echo "mock setting DOCKER_HOST"
  (
    set -e
    export DOCKER_HOST=an.invalid-host.tld
    export DOCKER_MACHINE_NAME=invalid-host

    # test build
    run $DEX image build imgtest/alpine
    [ $status -eq 0 ]

    # test ls
    run $DEX image ls
    [ $status -eq 0 ]
    [[ "$output" == *"$DEX_NAMESPACE/alpine"* ]]

    # test rm
    run $DEX image rm imgtest/alpine
    [ $status -eq 0 ]
  )

  run docker images -q $DEX_NAMESPACE/alpine:latest
  [ $status -eq 0 ]
  [ ${#lines[@]} -eq 0 ]
}
