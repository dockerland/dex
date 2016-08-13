
# dex-detect-imgstr accepts <[repo/]image|*> and sets
#  __source_match (source checkout, e.g. 'core', '*')
#  __image_match (source checkout image name, e.g. 'alpine', '*')
#  __image_tag (source checkout image tag, e.g. 'latest')
dex-detect-imgstr(){
  local vars=( __source_match __image_match __image_tag )
  local debug=${2:-false}

  for var in ${vars[@]}; do
    eval $var=
  done

  [ -z "$1" ] && return 1

  IFS='/'
  read -r remote imagestr <<< "$1"
  unset IFS

  if [ -z "$imagestr" ]; then
    __source_match="*"
    __image_match="$1"
  else
    __source_match="$remote"
    __image_match="$imagestr"

    if [ ! -d $DEX_HOME/checkouts/$__source_match ]; then
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


# dex-detect-sourcestr sets __sources (array of sources.list matches in "name url" format)
# usage: dex-detect-sourcestr <sourcestr|*>
#    ex: dex-detect-sourcestr core => 0: __sources=( "core git@github.com:dockerland/dex-dockerfiles-core.git" )
#    ex: dex-detect-sourcestr git@github.com:dockerland/dex-dockerfiles-core.git => 0: __sources=( "core git@github.com:dockerland/dex-dockerfiles-core.git" )
#    ex: dex-detect-sourcestr * => 0: __sources=( "core git@github.com:dockerland/dex-dockerfiles-core.git" "extra:git@github.com dockerland/dex-dockerfiles-extra.git" )
#    ex: dex-detect-sourcestr * => 1: __sources=( )
dex-detect-sourcestr(){
  __sources=()
  local retval=1

  [ -e $DEX_HOME/sources.list ] || {
    ERRCODE=127
    error "missing $DEX_HOME/sources.list"
  }

  while read name url junk ; do

    # skip blank, malformed, or comment lines
    if [ -z "$name" ] || [ -z "$url" ] || [[ $name = \#* ]]; then
      continue
    fi

    if [ "$1" = "*" ] || [ "$name" = "$1" ] ||  [ "$url" = "$1" ]; then
      __sources+=( "$name $url" )
      retval=0
    fi
  done < $DEX_HOME/sources.list

  return $retval
}
