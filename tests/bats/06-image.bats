#!/usr/bin/env bats

#
# 06 - runtime
#

#@TODO test build --pull
#@TODO test building packages
#@TODO betters tests

load dex

setup(){
  [ -e $DEX ] || install_dex

  if [ ! -d $DEX_HOME/checkouts/imgtest ]; then
    (
      set -e
      mk-repo
      cp_fixture images/ $MK_REPO
      cd $MK_REPO
      git add images
      git commit -m "adding image fixtures"
      $DEX remote --force add imgtest $MK_REPO
    ) || error "failed stubbing imgtest"

  fi

  export DEX_TAG_PREFIX="dex/v1-tests"

}

teardown(){
  for image in $(docker images -q --filter=label=dex-tag-prefix=$DEX_TAG_PREFIX); do
    docker rmi --force $image
  done
}

@test "image build creates an image from checkouts" {
  [ -d $DEX_HOME/checkouts/imgtest/images ]
  run docker rmi dex/v1-tests/alpine:latest
  run $DEX image build imgtest/alpine
  [ $status -eq 0 ]


  run docker images -q $DEX_TAG_PREFIX/alpine:latest
  [ $status -eq 0 ]
  [ ! -z "${lines[@]}" ]
}


@test "image build respects tags" {
  [ -d $DEX_HOME/checkouts/imgtest/images ]

  $DEX image build imgtest/alpine:3.2
  $DEX image build imgtest/alpine:edge

  run docker images -q --filter=label=dex-tag-prefix=$DEX_TAG_PREFIX --filter=label=dex-image=alpine
  echo $output
  [ ${#lines[@]} -eq 2 ]
}

@test "image build respects repo wildcards" {
  [ -d $DEX_HOME/checkouts/imgtest/images ]

  $DEX image build imgtest/*

  local image_count=$(ls -ld $DEX_HOME/checkouts/imgtest/images/* | wc -l)
  run docker images -q --filter=label=dex-tag-prefix=$DEX_TAG_PREFIX
  [ ${#lines[@]} -eq $image_count ]
}
