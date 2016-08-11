#
# lib.d/dex-run.sh for dex -*- shell-script -*-
#

dex-run(){
  # when installing, we prefix with "dex/$DEX_API-install"
  local namespace=${1:-$DEX_NAMESPACE}

  if [ -z "$LOOKUP" ]; then
    ERRCODE=2
    error "dex-run requires an [repository/]<image>[:tag] imgstr"
  fi

  dex-detect-imgstr $LOOKUP || error "lookup failed to parse $LOOKUP"
  local tag="$namespace/$__image_match:$__image_tag"

  #@TODO test special errcode for wildcard handling
  [[ $tag == *"*"* ]] && error "dex-run does not allow wildcards"

  # build image if it is missing
  image_api=$(docker inspect --format "{{ index .Config.Labels \"org.dockerland.dex.api\" }}" $tag)
  { [ $? -ne 0 ] || $BUILD_FLAG ; } && { dex-image-build || error "error building $tag" ; }

  [ -z "$image_api" ] && error \
    "the $tag image is missing a org.dockerland.dex.api label" \
    "please ensure you're up to date, rebuild it, or consult image maintainer"

  [ "$image_api" = "$DEX_API" ] || log \
    "warning, the $tag image is labeled for a different api." \
    "please ensure you're up to date, rebuild it, or consult image maintainer" \
    "current api: $DEX_API" \
    "$tag api: $image_api"

  # image is built and ready
  export __dex_image=$tag
  v1-runtime
  return $?
}
