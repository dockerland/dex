#
# lib.d/dex-remote.sh for dex -*- shell-script -*-
#

dex-remote-add(){
  if [ -z "$REMOTE_NAME" ] || [ -z "$REMOTE_URL" ]; then
    ERRCODE=2
    error "remote-add requires NAME and URL"
  fi

  if $FORCE_FLAG; then
    dex-remote-rm $REMOTE_NAME
  elif dex-remote-lookup $REMOTE_NAME || dex-remote-lookup $REMOTE_URL ; then
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


dex-remote-init(){

  dex-fetch "https://raw.githubusercontent.com/dockerland/dex/master/sources.list" $DEX_HOME/sources.list.fetched

  if [ ! -e $DEX_HOME/sources.list ]; then
    if [ -e $DEX_HOME/sources.list.fetched ]; then
      cat $DEX_HOME/sources.list.fetched > $DEX_HOME/sources.list || error \
        "error writing sources.list from fetched file"
    else
      dex-sources-cat > $DEX_HOME/sources.list || error \
        "error creating $DEX_HOME/sources.list"
    fi
  fi

}

# dex-remote-lookup <name|url>
# @returns 1 if not found
# @returns 0 if found, and sets DEX_REMOTE=<resolved-name>
dex-remote-lookup(){
  [ -e $DEX_HOME/sources.list ] || {
    ERRCODE=127
    error "missing $DEX_HOME/sources.list"
  }

  DEX_REMOTE=

  while read name url junk ; do

    # skip blank, malformed, or comment lines
    if [ -z "$name" ] || [ -z "$url" ] || [[ $name = \#* ]]; then
      continue
    fi

    if [ "$name" = "$1" ] ||  [ "$url" = "$1" ]; then
      DEX_REMOTE="$name"
      DEX_REMOTE_URL=$url
      return 0
    fi
  done < $DEX_HOME/sources.list

  return 1
}

dex-remote-ls(){
  [ ! -e $DEX_HOME/sources.list ] && \
    ERRCODE=127 && error "missing $DEX_HOME/sources.list"

  cat $DEX_HOME/sources.list |
  while read __source_name __source_url junk ; do

    # skip blank, malformed, or comment lines
    if [ -z "$__source_name" ] || [ -z "$__source_url" ] || [[ $__source_name = \#* ]]; then
      continue
    fi

    printf "$__source_name $__source_url\n"
  done
}

dex-remote-pull(){
  [ -z "$1" ] || REMOTE_LOOKUP=$1

  if [ -z "$REMOTE_LOOKUP" ]; then
    ERRCODE=2
    error "remote-pull requires a repository name or URL"
  fi

  dex-remote-lookup $REMOTE_LOOKUP || {
    [ -z "$1" ] && error "no match for $REMOTE_LOOKUP in sources.list"
    log "$REMOTE_LOOKUP not found, skipping pull..."
    return 1
  }

  if ! $FORCE_FLAG && is_dirty $DEX_HOME/checkouts/$DEX_REMOTE ]; then
    error "$DEX_HOME/checkouts/$DEX_REMOTE has local changes" \
    "pass --force to force update, or reset/upstream your changes"
  fi

  clone_or_pull $DEX_REMOTE_URL $DEX_HOME/checkouts/$DEX_REMOTE $FORCE_FLAG || \
    error "error pulling $DEX_REMOTE"

  log "$DEX_REMOTE updated"
}


dex-remote-rm(){
  [ -z "$1" ] || REMOTE_LOOKUP=$1

  if [ -z "$REMOTE_LOOKUP" ]; then
    ERRCODE=2
    error "remote-rm requires a repository name or URL"
  fi

  dex-remote-lookup $REMOTE_LOOKUP || {
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

    is_dirty $DEX_HOME/checkouts/$DEX_REMOTE ] && error \
      "$DEX_HOME/checkouts/$DEX_REMOTE has local changes" \
      "pass --force to force removal, or reset/upstream your changes"

    rm -rf $DEX_HOME/checkouts/$DEX_REMOTE
  fi

  sed_inplace $DEX_HOME/sources.list "/$DEX_REMOTE /d"
  log "removed $DEX_REMOTE"
}
