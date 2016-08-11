#
# lib.d/main_run.sh for dex -*- shell-script -*-
#

main_run(){

  local runstr="display_help"
  BUILD_FLAG=false
  PERSIST_FLAG=

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do

      case $1 in
        -b|--build)       BUILD_FLAG=true ;;
        -h|--help)        display_help ;;
        *)                arg_var "$1" LOOKUP && runstr="dex-run" ;;
      esac
      shift
    done
  fi

  dex-init
  $runstr
  exit $?
}


dex-run(){
  if [ -z "$LOOKUP" ]; then
    ERRCODE=2
    error "dex-run requires an [repository/]<image>[:tag] argument"
  fi
  dex-detect-imgstr$LOOKUP || error "lookup failed to parse $LOOKUP"

  local tag_prefix=${1:-$}
  local image=$tag_prefix/$DEX_REMOTE_IMAGESTR:$DEX_REMOTE_IMAGETAG

  docker inspect $image >/dev/null 2>&1
  { [ $? -ne 0 ] || $BUILD_FLAG ; } &&  dex-image-build

  # image is built and ready
  dex-run-image $image
  return $?
}
