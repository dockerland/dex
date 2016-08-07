#!/usr/bin/env bats

#
# 05 - runtime
#

load dex

setup(){
  [ -e $DEX ] || install_dex
}

lookup(){
  for line in $($DEX runfunc dex-set-lookup $1 true); do
    eval $line
  done
}

@test "lookup parses 'alpine' as '*/alpine:latest'" {
  lookup "alpine"
  [ "$DEX_REMOTE" = "*" ]
  [ "$DEX_REMOTE_IMAGESTR" = "alpine" ]
  [ "$DEX_REMOTE_IMAGETAG" = "latest" ]
}

@test "lookup parses 'alpine:3.2' as '*/alpine:3.2'" {
  lookup "alpine:3.2"
  [ "$DEX_REMOTE" = "*" ]
  [ "$DEX_REMOTE_IMAGESTR" = "alpine" ]
  [ "$DEX_REMOTE_IMAGETAG" = "3.2" ]
}

@test "lookup parses 'core/alpine:3.2' as 'core/alpine:3.2'" {
  lookup "core/alpine:3.2"
  [ "$DEX_REMOTE" = "core" ]
  [ "$DEX_REMOTE_IMAGESTR" = "alpine" ]
  [ "$DEX_REMOTE_IMAGETAG" = "3.2" ]
}
