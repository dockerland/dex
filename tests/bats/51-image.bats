#!/usr/bin/env bats

#
# 50 - runtime command behavior
#

load app

setup(){
  make/test-repo
}

rm/images(){
  for image in $(docker images -q --filter=label=org.dockerland.dex.namespace=$DEX_NAMESPACE); do
    docker rmi --force $image
  done
}

get/build-sha(){
  local image="$1"
  local tag="$2"
  docker inspect --type=container --format='{{ .Id }}' \
    $(docker/get/safe-name "$DEX_NAMESPACE/test-repo/$image:$tag" "dexbuild")
}

@test "image build creates docker images from repository checkouts" {
  rm/images
  [ -z "$(docker/local images -q $DEX_NAMESPACE/test-repo/alpine:latest)" ]
  [ -z "$(docker/local images -q $DEX_NAMESPACE/test-repo/debian:8)" ]

  run $APP image build test-repo/alpine:latest test-repo/debian:8
  [ -n "$(docker/local images -q $DEX_NAMESPACE/test-repo/alpine:latest)" ]
  [ -n "$(docker/local images -q $DEX_NAMESPACE/test-repo/debian:8)" ]
}

@test "image build spawns a unique 'build' container for each image built" {
  debian_sha="$(get/build-sha "debian" "8")"
  alpine_sha="$(get/build-sha "alpine" "latest")"
  [ "$debian_sha" != "$alpine_sha" ]

  # test new container happens on _each_ build
  run $APP image build test-repo/alpine:latest test-repo/debian:8
  [ "$(get/build-sha "debian" "8")" != "$debian_sha" ]
  [ "$(get/build-sha "alpine" "latest")" != "$alpine_sha" ]
}

@test "image build labels images according to runtime and build params" {
  app/var DEX_RUNTIME
  app/var DEX_NAMESPACE

  required_labels=(
    namespace
    runtime
    image
    repo
    tag
  )

  while read label value ; do
      label="${label//org.dockerland.dex./}"

      # remove label
      required_labels=( "${required_labels[@]//$label}" )

      # test value
      case "$label" in
        namespace) [ "$value" = "$DEX_NAMESPACE" ] ;;
        runtime) [ "$value" = "$DEX_RUNTIME" ] ;;
        image) [ "$value" = "alpine" ] ;;
        repo) [ "$value" = "test-repo" ] ;;
        tag) [ "$value" = "latest" ] ;;
        api) true ;;
        *) echo "unknown label $label" ; false ;;
      esac

  # use process substitution to avoid subshell and retain access to required_labels
done < <(docker/find/labels $DEX_NAMESPACE/test-repo/alpine:latest)


  if [ -n "$(io/trim "${required_labels[@]}")" ]; then
    echo "image is missing the following labels;"
    echo "${required_labels[@]}"
    false
  fi
}

@test "image build enables docker build cache by default" {
  skip
  #@TODO test cache + --no-cache flag
  # we had trouble because apparently docker build randomly assigns label order
}

@test "image build busts cache with the DEXBUILD_NOCACHE argument" {
  $APP image build test-repo/cachebust:nocache
  local sha_1=$(get/build-sha "cachebust" "nocache")

  $APP image build test-repo/cachebust:nocache
  local sha_2=$(get/build-sha "cachebust" "nocache")

  [ "$sha_1" != "$sha_2" ]
}

@test "image ls flags and output resemble 'docker images' command" {
  local filters=(
    "--filter=\"label=org.dockerland.dex.namespace=$DEX_NAMESPACE\""
    "--filter=label=org.dockerland.dex.repo=test-repo"
  )
  diff <($APP image ls test-repo/) <(docker images "${filters[@]}")
  diff <($APP image ls -q test-repo/) <(docker images -q "${filters[@]}")
}


@test "image ls flags and output resemble 'docker images' command" {
  local filters
  filters=(
    "--filter=\"label=org.dockerland.dex.namespace=$DEX_NAMESPACE\""
    "--filter=label=org.dockerland.dex.repo=test-repo"
  )
  diff <($APP image ls test-repo/) <(docker images "${filters[@]}")
  diff <($APP image ls -q test-repo/) <(docker images -q "${filters[@]}")
}

@test "image ls supports tag and image filters" {
  local filters
  filters=(
    "--filter=\"label=org.dockerland.dex.namespace=$DEX_NAMESPACE\""
    "--filter=label=org.dockerland.dex.repo=test-repo"
    "--filter=label=org.dockerland.dex.image=alpine"
  )
  diff <($APP image ls test-repo/alpine) <(docker images "${filters[@]}")

  filters=(
    "--filter=\"label=org.dockerland.dex.namespace=$DEX_NAMESPACE\""
    "--filter=label=org.dockerland.dex.repo=test-repo"
    "--filter=label=org.dockerland.dex.tag=latest"
  )

  diff <($APP image ls test-repo/:latest) <(docker images "${filters[@]}")
}

@test "image rm removes named images, prompts before removal" {
  yes "n" | $APP image rm test-repo/alpine:latest
  [ -n "$($APP image ls -q test-repo/alpine:latest)" ]
  [ -n "$($APP image ls -q test-repo/debian:8)" ]

  yes "y" | $APP image rm test-repo/alpine:latest
  [ -z "$($APP image ls -q test-repo/alpine:latest)" ]
  [ -n "$($APP image ls -q test-repo/debian:8)" ]
}

@test "image rm removes respects --force flag" {
  [ -n "$($APP image ls -q test-repo/debian:8)" ]

  $APP image rm --force test-repo/debian
  [ -z "$($APP image ls -q test-repo/debian:8)" ]
}


@test "image build|ls|rm always target local docker engine" {

  export DOCKER_HOST=an.invalid-host.tld
  export DOCKER_MACHINE_NAME=invalid-host

  $APP image build test-repo/alpine:latest
  [ -n $($APP image ls -q repo-test/alpine:latest) ]
  $APP image rm --force test-repo/alpine:latest
  [ -z $($APP image ls -q repo-test/alpine:latest) ]
}
