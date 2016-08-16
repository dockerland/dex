#!/usr/bin/env bats

#
# 07 - runtime
#

load dex

export DEX_NAMESPACE="dex/v1-tests"
export DEX_BIN_DIR=$TMPDIR/usr/local/bin/installs

setup(){
  [ -e $DEX ] || install_dex
  [ -d $DEX_BIN_DIR ] || mkdir -p $DEX_BIN_DIR
  mk-images
}

teardown(){
  chmod 755 $DEX_BIN_DIR
  rm -rf $DEX_BIN_DIR
}

imgcount(){
  echo $(ls -1 $DEX_BIN_DIR | wc -l)
}

@test "install errors if it cannot write(126)|access(127) DEX_BIN_DIR" {

  chmod 000 $DEX_BIN_DIR
  run $DEX install imgtest/alpine
  [ $status -eq 126 ]

  chmod 755 $DEX_BIN_DIR && rm -rf $DEX_BIN_DIR
  run $DEX install imgtest/alpine
  [ $status -eq 127 ]
}

@test "install errors if it cannot match any image(s)" {
  run $DEX install imgtest/certainly-missing
  [ $status -eq 2 ]
}

@test "install adds prefixed runtime script of matching image to DEX_BIN_DIR" {
  [ $(imgcount) -eq 0 ]
  eval $($DEX vars DEX_BIN_PREFIX)

  run $DEX install imgtest/alpine

  [ $status -eq 0 ]
  [ $(imgcount) -eq 1 ]
  [ -e $DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine ]
}

@test "install writes _behaving dexecutables_ to DEX_BIN_DIR"  {
  eval $($DEX vars DEX_BIN_PREFIX)
  run $DEX install imgtest/debian

  [ $status -eq 0 ]
  [ -x $DEX_BIN_DIR/${DEX_BIN_PREFIX}debian ]

  run $DEX_BIN_DIR/${DEX_BIN_PREFIX}debian
  [[ $output == *"DEBIAN_RELEASE"* ]]

  output=$(echo "foo" | $DEX_BIN_DIR/${DEX_BIN_PREFIX}debian sed 's/foo/bar/')
  [ $? -eq 0 ]
  [ "$output" = "bar" ]
}

@test "install adds matching images to DEX_BIN_DIR" {
  [ $(imgcount) -eq 0 ]

  local repo_image_count=$(ls -ld $DEX_HOME/checkouts/imgtest/images/* | wc -l)

  run $DEX install imgtest/*
  [ $status -eq 0 ]
  [ $(imgcount) -eq $repo_image_count ]
}

@test "install adds symlink to runtime script when --global flag is passed" {
  eval $($DEX vars DEX_BIN_PREFIX)
  run $DEX install --global imgtest/alpine

  [ $status -eq 0 ]
  [ -e $DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine ]
  [ -L $DEX_BIN_DIR/alpine ]
}

@test "install will not overwrite existing files, except when --force is passed" {

  eval $($DEX vars DEX_BIN_PREFIX)
  touch $DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine
  touch $DEX_BIN_DIR/alpine

  run $DEX install --global imgtest/alpine
  [[ $output = *"$DEX_BIN_DIR/${DEX_BIN_PREFIX}alpine exists"* ]]
  [[ $output = *"skipping global install"* ]]

  run $DEX install --global --force imgtest/alpine
  [ -L $DEX_BIN_DIR/alpine ]
}


#@TODO test label failures, e.g. when org.dockerland.dex.api is missing
