#!/usr/bin/env bats

#
# 21- - cli tests
#

load app

setup(){
  [ -d "$DEX_HOME/checkouts/find-test" ] || {
    mkdir -p "$DEX_HOME/checkouts/find-test/dex-images"
    fixture/cp "dex-images" "$DEX_HOME/checkouts/find-test/"
  }
}

@test "find-repostr output is parsable with IFS='/:'" {

  local repo
  local image
  local tag

  IFS="/:" read repo image tag <<< "$($APP runfunc dex/find-repostr "extra/alpine:latest")"
  [ "$repo" = "extra" ]
  [ "$image" = "alpine" ]
  [ "$tag" = "latest" ]

  IFS="/:" read repo image tag <<< "$($APP runfunc dex/find-repostr "extra/")"
  [ "$repo" = "extra" ]
  [ "$image" = "" ]
  [ "$tag" = "" ]

  IFS="/:" read repo image tag <<< "$($APP runfunc dex/find-repostr "alpine")"
  [ "$repo" = "" ]
  [ "$image" = "alpine" ]
  [ "$tag" = "" ]

  IFS="/:" read repo image tag <<< "$($APP runfunc dex/find-repostr ":macos")"
  [ "$repo" = "" ]
  [ "$image" = "" ]
  [ "$tag" = "macos" ]

}

@test "find-repostr respects default tags" {
  [ "$($APP runfunc dex/find-repostr "alpine" "latest")" = "/alpine:latest" ]
}

@test "find-repostr will not default tag on unspecified images" {
  [ "$($APP runfunc dex/find-repostr "extra/" "latest")" = "extra/:" ]
}

@test "find-dockerfiles returns available dockerfiles in repository checkouts" {
  count=$(find $DEX_HOME/checkouts/find-test/dex-images | grep Dockerfile | wc -l)
  run $APP runfunc dex/find-dockerfiles "find-test/"

  [ ${#lines[@]} -eq $count ]
}

@test "find-dockerfiles respects filtering dockerfiles by repostr" {
  count=$(find $DEX_HOME/checkouts/find-test/dex-images/alpine | grep Dockerfile | wc -l)
  run $APP runfunc dex/find-dockerfiles "find-test/alpine"
  [ ${#lines[@]} -eq $count ]

  run $APP runfunc dex/find-dockerfiles "find-test/alpine:latest"
  [ ${#lines[@]} -eq 1 ]
}


@test "find-repostr-from-dockerfile returns IFS parsable repostr" {
  dockerfile=$($APP runfunc dex/find-dockerfiles "find-test/alpine:latest")
  repostr=$($APP runfunc dex/find-repostr-from-dockerfile "$dockerfile")

  IFS="/:" read repo image tag <<< "$repostr"
  [ "$repo" = "find-test" ]
  [ "$image" = "alpine" ]
  [ "$tag" = "latest" ]
}
