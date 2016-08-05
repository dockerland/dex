#!/usr/bin/env bats

#
# 02 - configuration
#

load dex

setup(){
  [ -e $DEX ] || install_dex

  export DEX_NETWORK=false

  OUTFILE=/tmp/dex-google-output
  rm -rf $OUTFILE
}

teardown(){
  rm -rf $OUTFILE
}

@test "network silently refuses to fetch when disabled" {
  run $DEX runfunc dex-fetch https://google.com/ $OUTFILE

  echo $output
  $DEX vars DEX_NETWORK

  [ $status -eq 0 ]
  [ ! -e "$OUTFILE" ]
}

@test "network exits with status code 0 if disabled and errmessage provided" {
  run $DEX runfunc dex-fetch https://google.com/ $OUTFILE "error!"

  [ $status -eq 1 ]
  [ ! -e "$OUTFILE" ]
}

@test "network exits with status code 0 if enabled, has bad URL, and errmessage provided" {
  run $DEX runfunc dex-fetch https://999.999.999.999/ $OUTFILE "error!"

  [ $status -eq 1 ]
  [ ! -e "$OUTFILE" ]
}

@test "network properly fetches when enabled" {
  export DEX_NETWORK=true
  run $DEX runfunc dex-fetch https://google.com/ $OUTFILE "error!"

  echo $output
  echo "STATUS: $status"

  [ $status -eq 0 ]
  [ -e "$OUTFILE" ]
}
