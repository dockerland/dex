dex-ping(){
  echo "${1:-pong}"
  exit 0
}

# usage: dex-fetch <url> <target-path>
dex-fetch(){

  ! $DEX_NETWORK && \
    log "refused to fetch $2 from $1" "networking disabled" && \
    return 1

  fetch-url $1 $2
}

dex-init(){
  ERRCODE=126

  [ -d $DEX_HOME ] || mkdir -p $DEX_HOME || error \
    "could not create working directory \$DEX_HOME"

  [ -d $DEX_HOME/checkouts ] || mkdir -p $DEX_HOME/checkouts || error \
    "could not create checkout directory under \$DEX_HOME"

  ( type docker >/dev/null 2>&1 ) || error \
    "dex requires docker"

  [ -e $DEX_HOME/sources.list ] || dex-init-sources

  for path in $DEX_HOME $DEX_HOME/checkouts $DEX_HOME/sources.list; do
    [ -w $path ] || error "$path is not writable"
  done

  ERRCODE=1
  return 0
}

dex-init-sources(){

  if [ ! -e $DEX_HOME/sources.list ]; then
    if dex-fetch "https://raw.githubusercontent.com/dockerland/dex/master/sources.list" $DEX_HOME/sources.list.fetched ; then
      cat $DEX_HOME/sources.list.fetched > $DEX_HOME/sources.list || error \
        "error writing sources.list from fetched file"
    else
      dex-sources-cat > $DEX_HOME/sources.list || error \
        "error creating $DEX_HOME/sources.list"
    fi
  fi
  
  rm -rf $DEX_HOME/sources.list.fetched >/dev/null 2>&1
}

dex-sources-cat(){
  cat <<-EOF
#
# dex sources.list
#

core git@github.com:dockerland/dex-dockerfiles-core.git
extra git@github.com:dockerland/dex-dockerfiles-extra.git

EOF
}

runfunc(){
  [ "$(type -t $1)" = "function" ] || error \
    "$1 is not a valid runfunc target"

  eval "$@"
}
