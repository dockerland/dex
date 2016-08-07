#
# lib.d/main_remote.sh for dex -*- shell-script -*-
#

main_remote(){

  local runstr="display_help"
  FORCE_FLAG=false

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do

      #@TODO migrate to argparsing (getopts?) to supports add --force
      case $1 in
        add|ls|rm)        runstr="dex-remote-$1"
                          if [ $1 = "add" ]; then
                            arg_var $2 REMOTE_NAME && shift
                            arg_var $2 REMOTE_URL && shift
                          else
                            arg_var $2 REMOTE_LOOKUP && shift
                          fi
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

dex-remote-add(){
  if [ -z "$REMOTE_NAME" ] || [ -z "$REMOTE_URL" ]; then
    ERRCODE=2
    error "remote-add requires NAME and URL"
  fi

  if $FORCE_FLAG; then
    dex-remote-rm $REMOTE_NAME
  elif dex-sources-lookup $REMOTE_NAME || dex-sources-lookup $REMOTE_URL ; then
    ERRCODE=2
    error "refusing to add $REMOTE_NAME" "$DEX_REMOTE is a duplicate name|url"
  fi

  [ -e $DEX_HOME/checkouts/$REMOTE_NAME ] && {
    ERRCODE=2
    error "refusing to add $REMOTE_NAME" \
      "$DEX_HOME/checkouts/$REMOTE_NAME exists"
  }

  clone_or_pull $REMOTE_URL $DEX_HOME/checkouts/$REMOTE_NAME || error \
    "unable to add respository"

  echo "$REMOTE_NAME $REMOTE_URL" >> $DEX_HOME/sources.list || error \
    "unable to update sources.list"

  log "$REMOTE_NAME added"
}

dex-remote-ls(){
  [ ! -e $DEX_HOME/sources.list ] && \
    ERRCODE=127 && error "missing $DEX_HOME/sources.list"

  cat $DEX_HOME/sources.list |
  while read name url junk ; do

    # skip blank, malformed, or comment lines
    if [ -z "$name" ] || [ -z "$url" ] || [[ $name = \#* ]]; then
      continue
    fi

    printf "$name\t$url\n"
  done
}

dex-remote-pull(){
  error "pull not implemented"
}


dex-remote-rm(){
  [ -z "$1" ] || REMOTE_LOOKUP=$1

  if [ -z "$REMOTE_LOOKUP" ]; then
    ERRCODE=2
    error "remote-rm requires a repository name or URL"
  fi

  dex-sources-lookup $REMOTE_LOOKUP || {
    [ -z "$1" ] && error "no match for $REMOTE_LOOKUP in sources.list"
    log "$REMOTE_LOOKUP not found, skipping removal..."
    return 1
  }

  if $FORCE_FLAG; then
    rm -rf $DEX_HOME/checkouts/$DEX_REMOTE 2>/dev/null
  elif [ -d $DEX_HOME/checkouts/$DEX_REMOTE ]; then

    [ ! -w $DEX_HOME/checkouts/$DEX_REMOTE  ] && {
      ERRCODE=126
      error "$DEX_HOME/checkouts/$DEX_REMOTE" is not writable
    }

    is-dirty $DEX_HOME/checkouts/$DEX_REMOTE ] && error \
      "$DEX_HOME/checkouts/$DEX_REMOTE has local changes" \
      "pass --force to force removal, or reset/upstream your changes"

    rm -rf $DEX_HOME/checkouts/$DEX_REMOTE
  fi

  sed_inplace $DEX_HOME/sources.list "/$DEX_REMOTE /d"
  log "removed $DEX_REMOTE"
}
