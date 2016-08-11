
# dex-detect-imgstr accepts <[repo/]image|*> and sets
#  __repo_match (remote checkout, e.g. 'core', '*')
#  __image_match (remote checkout image name, e.g. 'alpine', '*')
#  __image_tag (remote checkout image tag, e.g. 'latest')
dex-detect-imgstr(){
  local vars=( __repo_match __image_match __image_tag )
  local debug=${2:-false}

  for var in ${vars[@]}; do
    eval $var=
  done

  [ -z "$1" ] && return 1

  IFS='/'
  read -r remote imagestr <<< "$1"
  unset IFS

  if [ -z "$imagestr" ]; then
    __repo_match="*"
    __image_match="$1"
  else
    __repo_match="$remote"
    __image_match="$imagestr"

    if [ ! -d $DEX_HOME/checkouts/$__repo_match ]; then
      log "warning, $remote is not checked out" \
      "  has it been added with dex remote?"
    fi
  fi

  IFS=':'
  read -r image tag <<< "$__image_match"
  unset IFS

  if [ -z "$tag" ]; then
    __image_tag="latest"
  else
    __image_match="$image"
    __image_tag="$tag"
  fi

  # if $2 is true, echo lines for evaluation
  $debug && dex-vars-print ${vars[@]}
  return 0
}
