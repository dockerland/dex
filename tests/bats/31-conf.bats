#!/usr/bin/env bats

#
# 30 - initialization and configuration
#

load app

reset/vars(){
  for var in "${APP_VARS[@]}"; do
    eval "unset \$var"
  done
}

default/val(){
  case "$1" in
    DEX_BIN_DIR) echo "$DEX_HOME/bin" ;;
    DEX_BIN_PREFIX) echo "d" ;;
    DEX_HOME) echo "$DEX_HOME" ;;
    DEX_NAMESPACE) echo "dex/v1" ;;
    DEX_NETWORK) echo "true" ;;
    DEX_REGISTRY) echo "true" ;;
    DEX_RUNTIME) echo "v1" ;;
    __checkouts) echo "$DEX_HOME/checkouts" ;;
    __sources) echo "$DEX_HOME/sources.list" ;;
    __sources_url) echo "https://raw.githubusercontent.com/dockerland/dex/master/v1-sources.list" ;;
    __defaults) echo "false" ;;
    __force) echo "false" ;;
    __format) echo "" ;;
    __pull) echo "false" ;;
    *) echo "unrecognized var: $1" ; retval=1 ;;
  esac
}

@test "conf vars prints evaluable output defining APP_VARS" {
  reset/vars
  eval $($APP conf vars)

  for var in "${APP_VARS[@]}"; do
    eval "[ -n \"\$var\" ]"
  done
}

@test "conf vars prints evaluable output for fish|powershell" {
  #@TODO -- implement
  skip
}

@test "conf vars respects limiting output to passed variable names" {
  reset/vars
  eval $($APP conf vars -- DEX_BIN_PREFIX DEX_BIN_DIR )
  [ -n "$DEX_BIN_PREFIX" ]
  [ -n "$DEX_BIN_DIR" ]
  [ -z "$DEX_RUNTIME" ]

}

@test "conf vars reflects current environment settings" {
  export DEX_RUNTIME="zzz"
  run $APP conf vars -- DEX_RUNTIME
  [[ "$output" == *"DEX_RUNTIME=\"zzz\""* ]]
}

@test "conf vars --defaults ignores current environment settings" {
  export DEX_BIN_DIR="zzz"
  export DEX_BIN_PREFIX="zzz"
  export DEX_HOME="$TMPDIR/zzz"
  export DEX_NAMESPACE="zzz"
  export DEX_NETWORK=false
  export DEX_REGISTRY=false
  export DEX_RUNTIME="zzz"

  eval $($APP conf vars --defaults)

  for var in "${APP_VARS[@]}"; do
    echo "$var"
    #echo $(default/val $var)
    #eval "echo \"\$$var\""
    eval "[ \"$(default/val $var)\" = \"\$$var\" ]"
  done
}


@test "internal vars get initialized to defaults" {

  local ivars=(
    __checkouts
    __sources
    __sources_url
    __defaults
    __force
    __pull
    __format
  )

  eval $($APP conf vars -- "${ivars[@]}")
  for var in "${ivars[@]}"; do
    echo "$var"
    #echo $(default/val $var)
    #eval "echo \"\$$var\""
    eval "[ \"$(default/val $var)\" = \"\$$var\" ]"
  done
}
