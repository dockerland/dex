#!/usr/bin/env bats

#
# 05 - runtime
#

load dex

setup(){
  [ -e $DEX ] || install_dex
}

lookup(){
  for line in $($DEX runfunc dex-detect-imgstr $1 true); do
    eval $line
  done
}

@test "lookup parses 'alpine' as '*/alpine:latest'" {
  lookup "alpine"
  [ "$__repo_match" = "*" ]
  [ "$__image_match" = "alpine" ]
  [ "$__image_tag" = "latest" ]
}

@test "lookup parses 'alpine:3.2' as '*/alpine:3.2'" {
  lookup "alpine:3.2"
  [ "$__repo_match" = "*" ]
  [ "$__image_match" = "alpine" ]
  [ "$__image_tag" = "3.2" ]
}

@test "lookup parses 'core/alpine:3.2' as 'core/alpine:3.2'" {
  lookup "core/alpine:3.2"
  [ "$__repo_match" = "core" ]
  [ "$__image_match" = "alpine" ]
  [ "$__image_tag" = "3.2" ]
}
