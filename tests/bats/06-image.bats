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
  mk-images
}

@test "image build creates an image from checkouts" {
  [ -d $DEX_HOME/checkouts/imgtest/images ]

  rm-images
  run $DEX image build imgtest/alpine
  [ $status -eq 0 ]


  run docker images -q $DEX_NAMESPACE/alpine:latest
  [ $status -eq 0 ]
  [ ${#lines[@]} -eq 1 ]
}

@test "image build labels images according to the current DEX_API" {

  local img=$(docker images -q $DEX_NAMESPACE/alpine:latest)
  local api_version=$($DEX vars DEX_API | sed 's/DEX_API=//')

  [ ! -z "$img" ]
  [ ! -z "$api_version" ]

  echo "IMAGE: $img"

  for label in api build-api build-imgstr build-tag image namespace remote; do

    val=$(docker inspect --format "{{ index .Config.Labels \"org.dockerland.dex.$label\" }}" $img)
    echo "$label=$val"

    case $label in
      api) [ "$val" = "$api_version" ];;
      build-*) [ -z "$val" ] && echo "$label is not set" && false ;;
      image) [ "$val" = "alpine" ] ;;
      namespace) [ "$val" = "$DEX_NAMESPACE" ] ;;
      remote) [ "$val" = "imgtest" ] ;;
      *) echo "unknown label - $label" && false ;;
    esac
  done
}

@test "image build respects tags" {
  [ -d $DEX_HOME/checkouts/imgtest/images ]

  rm-images
  $DEX image build imgtest/alpine:3.2
  $DEX image build imgtest/alpine:edge

  run docker images -q $IMAGES_FILTER --filter=label=org.dockerland.dex.image=alpine
  echo $output
  [ ${#lines[@]} -eq 2 ]
}

@test "image build respects repo wildcards" {
  [ -d $DEX_HOME/checkouts/imgtest/images ]

  rm-images
  $DEX image build imgtest/*

  local repo_image_count=$(ls -ld $DEX_HOME/checkouts/imgtest/images/* | wc -l)
  run docker images -q $IMAGES_FILTER
  [ ${#lines[@]} -eq $repo_image_count ]
}

@test "image ls output matches 'docker images' and supports quiet flag" {
  diff <($DEX image ls -q) <(docker images -q $IMAGES_FILTER)
  ! diff <($DEX image ls) <(docker images -q $IMAGES_FILTER)
}

@test "image rm errors if it cannot find images to remove" {
  run $DEX image rm imgtest/zzz
  [ $status -eq 1 ]
}

@test "image rm respects repo wildcards" {
  local image_count=$(docker images -q $IMAGES_FILTER | wc -l)
  [ ! $image_count -eq 0 ]

  run $DEX image rm imgtest/*
  [ $status -eq 0 ]

  image_count=$(docker images -q $IMAGES_FILTER | wc -l)
  [ $image_count -eq 0 ]
}
