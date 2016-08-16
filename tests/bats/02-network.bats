#!/usr/bin/env bats

#
# 02 - configuration
#

load dex

setup(){
  [ -e $DEX ] || install_dex
  OUTFILE=/tmp/dex-google-output
  rm -rf $OUTFILE
}

teardown(){
  rm -rf $OUTFILE
}

@test "network refuses to fetch when disabled" {
  run $DEX runfunc dex-fetch https://google.com/ $OUTFILE

  [ $status -eq 1 ]
  [[ $output == *"refused to fetch"* ]]
  [ ! -e "$OUTFILE" ]
}

@test "network exits with status code 2 when enabled and missing tools" {
  $SKIP_NETWORK_TEST && skip
  export DEX_NETWORK=true
  export CURL_PATH=/bin/not-curl
  export WGET_PATH=/bin/not-wget

  run $DEX runfunc dex-fetch https://999.999.999.999/ $OUTFILE

  [ $status -eq 2 ]
  [ ! -e "$OUTFILE" ]
}

@test "network exits with status code 126 when enabled fetch fails" {
  $SKIP_NETWORK_TEST && skip
  export DEX_NETWORK=true

  run $DEX runfunc dex-fetch https://999.999.999.999/ $OUTFILE

  echo $output
  echo "status $status"

  [ $status -eq 126 ]
  [ ! -e "$OUTFILE" ]
}

@test "network properly fetches when enabled" {
  $SKIP_NETWORK_TEST && skip
  export DEX_NETWORK=true

  run $DEX runfunc dex-fetch https://google.com/ $OUTFILE

  echo $output
  echo "STATUS: $status"

  [ $status -eq 0 ]
  [ -e "$OUTFILE" ]
}
