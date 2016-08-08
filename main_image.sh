#
# lib.d/main_image.sh for dex -*- shell-script -*-
#

#@TODO implement package building (in repositories as well -- symlink strategy)
#@TODO implement --pull to update sources
#@TODO fix argparsing, build only accepts a single argument

main_image(){

  local runstr="display_help"
  FORCE_FLAG=false

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do

      case $1 in
        build|rm)         runstr="dex-image-$1"
                          arg_var "$2" LOOKUP && shift
                          ;;
        -f|--force)       FORCE_FLAG=true ;;
        -h|--help)        display_help ;;
        *)                unrecognized_arg "$1" ;;
      esac
      shift
    done
  fi

  dex-setup
  $runstr
  exit $?

}


dex-image-build(){
  if [ -z "$LOOKUP" ]; then
    ERRCODE=2
    error "image-add requires an image name, package name, or wildcard match to install"
  fi

  dex-set-lookup $LOOKUP

  # when installing, we prefix with "dex/$DEX_API-install"
  local built_image=false
  local tag_prefix=${1:-$DEX_TAG_PREFIX}

  for repo_dir in $(ls -d $DEX_HOME/checkouts/$DEX_REMOTE 2>/dev/null); do

    for image_dir in $(ls -d $repo_dir/images/$DEX_REMOTE_IMAGESTR 2>/dev/null); do
      (
        cd $image_dir
        if [ "$DEX_REMOTE_IMAGETAG" = "latest" ]; then
          dockerfile="Dockerfile"
        else
          dockerfile="Dockerfile-$DEX_REMOTE_IMAGETAG"
        fi

        [ -e $dockerfile ] || exit 1

        docker build \
          -t $tag_prefix/$(basename $image_dir):$DEX_REMOTE_IMAGETAG \
          --label=dex-api=$DEX_API \
          --label=dex-tag-prefix=$tag_prefix \
          --label=dex-image=$(basename $image_dir) \
          --label=dex-tag=$DEX_REMOTE_IMAGETAG \
          --label=dex-remote=$DEX_REMOTE \
          -f $dockerfile .
      ) && built_image=true
    done

    $built_image && {
      log "built $DEX_REMOTE/$DEX_REMOTE_IMAGESTR"
      exit 0
    }
  done

  error "failed to find $DEX_REMOTE/$DEX_REMOTE_IMAGESTR"
}


dex-image-rm(){
  if [ -z "$LOOKUP" ]; then
    ERRCODE=2
    error "image-rm requires an image name, package name, or wildcard match to install"
  fi

  dex-set-lookup $LOOKUP

  local removed_image=false
  local tag_prefix=${1:-$DEX_TAG_PREFIX}
  local filters="--filter=label=dex-tag-prefix=$DEX_TAG_PREFIX"
  local force_flag=
  $FORCE_FLAG && force_flag="--force"


  [ ! "$DEX_REMOTE" = "*" ] && \
    filters="$filters --filter=label=dex-remote=$DEX_REMOTE"

  [ ! "$DEX_REMOTE_IMAGESTR" = "*" ] && \
    filters="$filters --filter=label=dex-image=$DEX_REMOTE_IMAGESTR"

  [ ! "$DEX_REMOTE_IMAGETAG" = "latest" ] && \
    filters="$filters --filter=label=dex-tag=$DEX_REMOTE_IMAGETAG"

  for image in $(docker images -q $filters); do
    #@TODO stop running containers?
    docker rmi $force_flag $image && removed_image=true
  done

  $removed_image && {
    log "removed $DEX_REMOTE/$DEX_REMOTE_IMAGESTR"
    exit 0
  }

  error "failed to remove any images matching $DEX_REMOTE/$DEX_REMOTE_IMAGESTR"
}
