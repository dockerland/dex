

# dex-image-build expects __imsgstr and builds images(s) from detected sources.
#  accepts [optional] namespace, sets __built_images array.
#
# usage: dex-image-build [namespace]
#    ex: __imgstr="alpine" ; dex-image-build => 1: __built_images=( "dex/v1/alpine:latest" )
#    ex: __imgstr="alpine" ; dex-image-build dex/v1-install => 1: __built_images=( "dex/v1-install/alpine:latest" )
#    ex: __imgstr="invalid-image-name" ; dex-image-build => 1: __built_images=( )

dex-image-build(){
  # when installing, we prefix with "dex/$DEX_RUNTIME-install"
  local namespace=${1:-$DEX_NAMESPACE}
  __built_images=()

  [ -z "$__imgstr" ] && error_exception \
    "image-build requires an [repository/]<image>[:tag] imgstr"

  dex-detect-imgstr $__imgstr || error "lookup failed to parse $__imgstr"


  log "* building $__source_match/$__image_match images..."

  for repo_dir in $(ls -d $DEX_HOME/checkouts/$__source_match 2>/dev/null); do
    for image_dir in $(ls -d $repo_dir/dex-images/$__image_match 2>/dev/null); do
      if [ "$__image_tag" = "latest" ]; then
        dockerfile="Dockerfile"
      else
        dockerfile="Dockerfile-$__image_tag"
      fi
      [ -e $image_dir/$dockerfile ] || continue

      local image=$(basename $image_dir)
      local source=$(basename $repo_dir)
      local tag="$namespace/$image:$__image_tag"
      local random=$(LC_CTYPE=C tr -dc 'a-zA-Z0-9-_' < /dev/urandom | head -c10)
      local cachebust=
      local pull=

      log "- building $tag"
      (
        set -e
        cd $image_dir

        # add cachebusting argument if requested/used in Dockerfile
        grep -q "^ARG CACHE_BUST" $dockerfile &&  \
          cachebust="--build-arg CACHE_BUST=$random"

        $__pull_flag && \
          pull="--pull"

        __local_docker build -t $tag $cachebust $pull \
          --label=org.dockerland.dex.build-api=$DEX_RUNTIME \
          --label=org.dockerland.dex.build-imgstr="$__imgstr" \
          --label=org.dockerland.dex.build-tag="$__image_tag" \
          --label=org.dockerland.dex.image=$image \
          --label=org.dockerland.dex.namespace=$namespace \
          --label=org.dockerland.dex.source=$source \
          -f $dockerfile .
      ) && __built_images+=( "$tag" )

    done
  done

  if [ ${#__built_images[@]} -gt 0 ]; then
    for __image in ${__built_images[@]}; do
      # force re-create "build" container
      dex-image-build-container $__image true &>/dev/null
      log "+ built $__image"
    done
    return 0
  else
    return 1
  fi
}


dex-image-ls(){
  local namespace=${1:-$DEX_NAMESPACE}
  if $__skip_namespace; then
    local filters="--filter=label=org.dockerland.dex.namespace"
  else
    local filters="--filter=label=org.dockerland.dex.namespace=$namespace"
  fi

  if [ ! -z "$__imgstr" ]; then
    dex-detect-imgstr $__imgstr

    [ ! "$__source_match" = "*" ] && \
      filters="$filters --filter=label=org.dockerland.dex.source=$__source_match"

    #@TODO support wildcards in image_match by switching to repository:tag form
    [ ! "$__image_match" = "*" ] && \
      filters="$filters --filter=label=org.dockerland.dex.image=$__image_match"

    [ ! "$__image_tag" = "*" ] && \
      filters="$filters --filter=label=org.dockerland.dex.build-tag=$__image_tag"
  fi

  __local_docker images $QUIET_FLAG $filters
}


dex-image-rm(){
  local namespace=${1:-$DEX_NAMESPACE}
  local removed_image=false
  local force_flag=
  $__force_flag && force_flag="--force"

  [ -z "$__imgstr" ] && error_exception \
    "image-rm requires an [repository/]<image>[:tag] imgstr"

  QUIET_FLAG="-q"
  for image in $(dex-image-ls $namespace); do
    __local_docker rmi $force_flag $image && removed_image=true
  done

  $removed_image && {
    log "removed $__source_match/$__image_match"
    exit 0
  }

  error "failed to remove any images matching $__imgstr"
}

# dex-image-build-container - ensure a container is accessible for an image
#  expects image name, prints container sha or returns 1 if no missing.
#
#  build containers are useful for pulling files out of a container during
#  runtime, e.g. to augment /etc/passwd. prints the sha of build container.
#
# usage: dex-image-build-container <image name> [force-recreate]
dex-image-build-container(){
  local name=$(docker_safe_name "$1" "dexbuild")
  local recreate=${2:-false}
  __image_container=
  (
    exec &>/dev/null
    $recreate && __local_docker rm --force $name
    __local_docker inspect $name || {
      __local_docker run --entrypoint=false --name=$name $1
    }
  )
  __local_docker inspect -f "{{ .Id }}" $name 2>/dev/null || return 1
}
