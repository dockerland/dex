
dex-image-build(){
  # when installing, we prefix with "dex/$DEX_API-install"
  local namespace=${1:-$DEX_NAMESPACE}
  local built_image=false

  if [ -z "$LOOKUP" ]; then
    ERRCODE=2
    error "image-build requires an image name, package name, or wildcard match to install"
  fi

  dex-detect-imgstr $LOOKUP || error "lookup failed to parse $LOOKUP"

  for repo_dir in $(ls -d $DEX_HOME/checkouts/$__source_match 2>/dev/null); do
    for image_dir in $(ls -d $repo_dir/images/$__image_match 2>/dev/null); do
      if [ "$__image_tag" = "latest" ]; then
        dockerfile="Dockerfile"
      else
        dockerfile="Dockerfile-$__image_tag"
      fi
      [ -e $image_dir/$dockerfile ] || continue

      local image=$(basename $image_dir)
      local source=$(basename $repo_dir)
      local tag="$namespace/$image:$__image_tag"

      log "building $tag ..."
      (
        set -e
        cd $image_dir
        docker build -t $tag \
          --label=org.dockerland.dex.build-api=$DEX_API \
          --label=org.dockerland.dex.build-imgstr="$LOOKUP" \
          --label=org.dockerland.dex.build-tag="$__image_tag" \
          --label=org.dockerland.dex.image=$image \
          --label=org.dockerland.dex.namespace=$namespace \
          --label=org.dockerland.dex.source=$source \
          -f $dockerfile .
      ) && built_image=true
    done
  done

  $built_image && {
    log "built $__source_match/$__image_match"
    return 0
  }

  error "failed to find images matching $__source_match/$__image_match"
}


dex-image-ls(){
  local namespace=${1:-$DEX_NAMESPACE}
  if $SKIP_NAMESPACE; then
    local filters="--filter=label=org.dockerland.dex.namespace"
  else
    local filters="--filter=label=org.dockerland.dex.namespace=$namespace"
  fi

  if [ ! -z "$LOOKUP" ]; then
    dex-detect-imgstr $LOOKUP

    [ ! "$__source_match" = "*" ] && \
      filters="$filters --filter=label=org.dockerland.dex.source=$__source_match"

    #@TODO support wildcards in image_match by switching to repository:tag form
    [ ! "$__image_match" = "*" ] && \
      filters="$filters --filter=label=org.dockerland.dex.image=$__image_match"

    [ ! "$__image_tag" = "*" ] && \
      filters="$filters --filter=label=org.dockerland.dex.build-tag=$__image_tag"
  fi

  docker images $QUIET_FLAG $filters
}


dex-image-rm(){
  local namespace=${1:-$DEX_NAMESPACE}
  local removed_image=false
  local force_flag=
  $FORCE_FLAG && force_flag="--force"

  if [ -z "$LOOKUP" ]; then
    ERRCODE=2
    error "image-rm requires an image name, package name, or wildcard match to install"
  fi

  QUIET_FLAG="-q"
  for image in $(dex-image-ls $namespace); do
    docker rmi $force_flag $image && removed_image=true
  done

  $removed_image && {
    log "removed $__source_match/$__image_match"
    exit 0
  }

  error "failed to remove any images matching $LOOKUP"
}
