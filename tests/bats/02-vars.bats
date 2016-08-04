#!/usr/bin/env bats

#
# 02 - configuration
#

load dex

setup(){
  [ -e $DEX ] || install_dex
}

@test "vars prints helpful output matching our fixture" {
  diff <(cat_fixture help-vars.txt) <($DEX vars --help)
  diff <(cat_fixture help-vars.txt) <($DEX vars -h)
  diff <(cat_fixture help-vars.txt) <($DEX help vars)
}

@test "vars DEX_BINDIR prints an evaluable line reflecting DEX_BINDIR default value" {
  run $DEX vars DEX_BINDIR
  [ $status -eq 0 ]
  [ $output = "DEX_BINDIR=/usr/local/bin" ]
}

@test "vars exits with status code 127 on invalid configuration variable lookups" {
  run $DEX vars INVALID_VAR
  [ $status -eq 127 ]
}

@test "vars prints evaluable lines matching defaults" {
  run $DEX vars all
  [ $status -eq 0 ]
  for line in "${lines[@]}"; do
    eval $line
    echo $line
  done

  [ "$DEX_HOME" = "//.dex" ]
  [ "$DEX_BINDIR" = "/usr/local/bin" ]
  [ "$DEX_PREFIX" = "d" ]
}

@test "vars prints evaluable lines reflecting registration of exported configuration" {
  export DEX_HOME="/myhome"
  export DEX_BINDIR="/mybin"
  export DEX_PREFIX="my"

  run $DEX vars all
  [ $status -eq 0 ]
  for line in "${lines[@]}"; do
    eval $line
    echo $line
  done

  [ "$DEX_HOME" = "/myhome" ]
  [ "$DEX_BINDIR" = "/mybin" ]
  [ "$DEX_PREFIX" = "my" ]
}

@test "vars --defaults prints evaluable lines resetting configuration to defaults" {

  run $DEX vars --defaults all
  [ $status -eq 0 ]
  for line in "${lines[@]}"; do
    eval $line
    echo $line
  done

  [ "$DEX_HOME" = "//.dex" ]
  [ "$DEX_BINDIR" = "/usr/local/bin" ]
  [ "$DEX_PREFIX" = "d" ]

}
