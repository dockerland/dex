



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
    # remove any 'build' containers
    for container in $(__local_docker ps -aq --filter "ancestor=$image" --filter "name=_dexbuild"); do
      __local_docker rm --force $container &>/dev/null
    done

    # remove image
    __local_docker rmi $force_flag $image && removed_image=true
  done

  $removed_image && {
    log "removed $__source_match/$__image_match"
    exit 0
  }

  error "failed to remove any images matching $__imgstr"
}
