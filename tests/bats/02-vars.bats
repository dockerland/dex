#!/usr/bin/env bats

#
# 02 - configuration
#

load dex

setup(){
  [ -e $DEX ] || install_dex
  reset_vars
}

set_vars(){
  export DEX_HOME="/myhome"
  export DEX_BINDIR="/mybin"
  export DEX_PREFIX="my"
  export DEX_NETWORK=false
  export DEX_API=v9000
}

reset_vars(){
  for var in ${DEX_VARS[@]}; do
    unset $var
  done
}

compare_defaults(){

  if [ $# -eq 0 ]; then
    echo "no lines passed to compare_defaults"
    return 1
  fi

  for line in $@; do
    IFS='='
    read -r var val <<< "$line"
    echo "comparing $var=$val"
    case $var in
      DEX_HOME) [ $val = "$TMPDIR/home/.dex" ] || retval=1 ;;
      DEX_BINDIR) [ $val = "/usr/local/bin" ] || retval=1 ;;
      DEX_PREFIX) [ $val = "d" ] || retval=1 ;;
      DEX_NETWORK) $val || retval=1 ;;
      DEX_API) [ $val = 'v1' ] || retval=1 ;;
      *) echo "unrecognized var: $var" ; retval=1 ;;
    esac
  done

  return $retval
}

@test "vars prints helpful output matching our fixture" {
  diff <(cat_fixture help-vars.txt) <($DEX vars --help)
  diff <(cat_fixture help-vars.txt) <($DEX vars -h)
  diff <(cat_fixture help-vars.txt) <($DEX help vars)
}

@test "vars prints a single variable, reflecting its default value" {
  run $DEX vars DEX_BINDIR
  [ $status -eq 0 ]
  [ $output = "DEX_BINDIR=/usr/local/bin" ]
}

@test "vars exits with status code 127 on invalid configuration variable lookups" {
  run $DEX vars INVALID_VAR
  [ $status -eq 127 ]
}

@test "vars prints evaluable lines matching configuration defaults" {
  run $DEX vars all

  [ $status -eq 0 ]
  for line in "${lines[@]}"; do
    eval $line
  done
  compare_defaults "${lines[@]}"
}

@test "vars prints evaluable lines reflecting registration of exported configuration" {

  set_vars
  run $DEX vars all

  [ $status -eq 0 ]
  for line in "${lines[@]}"; do
    eval $line
  done

  [ "$DEX_HOME" = "/myhome" ]
  [ "$DEX_BINDIR" = "/mybin" ]
  [ "$DEX_PREFIX" = "my" ]
  ! $DEX_NETWORK
}

@test "vars --defaults prints evaluable lines resetting configuration to defaults" {

  set_vars
  run $DEX vars --defaults all

  [ $status -eq 0 ]
  for line in "${lines[@]}"; do
    eval $line
  done

  run $DEX vars all
  compare_defaults "${lines[@]}"
}
