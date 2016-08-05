#
# lib.d/function.sh for dex -*- shell-script -*-
#

error(){
  printf "\e[31m%s\n\e[0m" "$@" >&2
  exit ${ERRCODE:-1}
}

log(){
  printf "\e[33m%s\n\e[0m" "$@" >&2
}

prompt_confirm() {
  while true; do
    echo
    read -r -n 1 -p "  ${1:-Continue?} [y/n]: " REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac
  done
}

runfunc(){
  [ "$(type -t $1)" = "function" ] || error \
    "$1 is not a valid runfunc target"

  $@
}

unrecognized_arg(){

  if [ $CMD = "main" ]; then
    printf "\n\n$1 is an unrecognized command\n\n"
  else
    printf "\n\n$1 is an unrecognized argument to the $CMD command.\n\n"
  fi

  display_help 127

}


vars_load(){
  while [ $# -ne 0 ]; do
    case $1 in
      DEX_HOME) DEX_HOME=${DEX_HOME:-~/.dex} ;;
      DEX_BINDIR) DEX_BINDIR=${DEX_BINDIR:-/usr/local/bin} ;;
      DEX_PREFIX) DEX_PREFIX=${DEX_PREFIX:-'d'} ;;
      DEX_NETWORK) DEX_NETWORK=${DEX_NETWORK:-true} ;;
      *) ERRCODE=127; error "$1 has no default configuration value" ;;
    esac
    shift
  done
}

vars_reset(){
  while [ $# -ne 0 ]; do
    unset $1
    shift
  done
}

vars_print(){
  while [ $# -ne 0 ]; do
    eval "printf \"$1=\$$1\n\""
    shift
  done
}

vars_print_export(){
  # TODO -- shell detection for fish|export
  while [ $# -ne 0 ]; do
    eval "printf \"export $1=\$$1\n\""
    shift
  done

  printf "# Run this command to configure your shell: \n"
  printf "# eval \$($ORIG_CMD)\n\n"
}


#
# dex
#


dex-ping(){
  echo "${1:-pong}"
  exit 0
}

# usage: dex-fetch <url> <target-path>
dex-fetch(){

  ! $DEX_NETWORK && \
    log "refused to fetch $2 from $1" "networking disabled" && \
    return 1

  local WGET_PATH=${WGET_PATH:-wget}
  local CURL_PATH=${CURL_PATH:-curl}

  if ( type $WGET_PATH >/dev/null 2>&1 ); then
    $WGET_PATH $1 -O $2
  elif ( type $CURL_PATH >/dev/null 2>&1 ); then
    $CURL_PATH -Lfo $2 $1
  else
    log "failed to fetch $2 from $1" "missing curl and wget"
    return 2
  fi

  [ $? -eq 0 ] && \
    log "fetched fetch $2 from $1" && \
    return 0

  log "failed to fetch $2 from $1"
  return 126
}

dex-fetch-sources(){

  dex-fetch "https://raw.githubusercontent.com/dockerland/dex/briceburg/wonky/sources.list" $DEX_HOME/sources.list.fetched

  if [ ! -e $DEX_HOME/sources.list ]; then
    if [ -e $DEX_HOME/sources.list.fetched ]; then
      cat $DEX_HOME/sources.list.fetched > $DEX_HOME/sources.list || error \
        "error writing sources.list from fetched file"
    else
      dex-cat-sources > $DEX_HOME/sources.list || error \
        "error creating $DEX_HOME/sources.list"
    fi
  fi

}

dex-setup(){
  ERRCODE=126

  [ -d $DEX_HOME ] || mkdir -p $DEX_HOME || error \
    "could not create working directory \$DEX_HOME"

  [ -d $DEX_HOME/checkouts ] || mkdir -p $DEX_HOME/checkouts || error \
    "could not create checkout directory under \$DEX_HOME"

  [ -e $DEX_HOME/sources.list ] || dex-fetch-sources

  for path in $DEX_HOME $DEX_HOME/checkouts $DEX_HOME/sources.list; do
    [ -w $path ] || error "$path is not writable"
  done

  ERRCODE=1
  return 0
}

dex-cat-sources(){
  cat <<-EOF
#
# dex sources.list
#

core git@github.com:dockerland/dex-dockerfiles-core.git
extra git@github.com:dockerland/dex-dockerfiles-extra.git

EOF
}
