#
# lib.d/dex-remote.sh for dex -*- shell-script -*-
#

dex-remote-add(){
  if [ -z "$__remote_name" ] || [ -z "$__remote_url" ]; then
    ERRCODE=2
    error "remote-add requires NAME and URL"
  fi

  if $FORCE_FLAG; then
    dex-remote-rm "$__remote_name"
  elif dex-detect-sourcestr "$__remote_name" || dex-detect-sourcestr "$__remote_url" ; then
    ERRCODE=2
    error "refusing to add $__remote_name" "${__sources[@]} is a duplicate name|url"
  fi

  [ -e $DEX_HOME/checkouts/$__remote_name ] && {
    ERRCODE=2
    error "refusing to add $__remote_name" \
      "checkout $DEX_HOME/checkouts/$__remote_name already exists" \
      "use --force flag to overwrite"
  }

  clone_or_pull "$__remote_url" "$DEX_HOME/checkouts/$__remote_name" || error \
    "unable to add respository"

  echo "$__remote_name $__remote_url" >> $DEX_HOME/sources.list || error \
    "unable to update sources.list"

  log "$__remote_name added"
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

# dex-remote-pull updates a source checkout. updates all sources if * is passed.
# usage: dex-remote-pull <repostr|*>
#    ex: dex-remote-pull core
#    ex: dex-remote-pull git@github.com:dockerland/dex-dockerfiles-core.git
#    ex: dex-remote pull *
dex-remote-pull(){
  [ -z "$1" ] || __sourcestr="$1"

  if [ -z "$__sourcestr" ]; then
    ERRCODE=2
    error "remote-pull requires a repository name or URL"
  fi

  dex-detect-sourcestr "$__sourcestr" || {
    [ -z "$1" ] && error "no match for $__sourcestr in sources.list"
    log "$__sourcestr not found, skipping pull..."
    return 1
  }

  for __source in "${__sources[@]}"; do
    read -r __source_name __source_url <<< "$__source"

    if ! $FORCE_FLAG && is_dirty $__checkouts/$__source_name ]; then
      error "$DEX_HOME/checkouts/$__source_name has local changes" \
      "pass --force to force update, or reset/upstream your changes"
    fi

    ! $DEX_NETWORK && [[ ! "$__source_url" == /* ]] && {
      log "skipping $__source_name -- networking disabled"
      continue
    }


    clone_or_pull $__source_url $__checkouts/$__source_name $FORCE_FLAG || \
      error "error pulling $__source_name"

    log "$__source_name updated"
  done
}


dex-remote-rm(){
  [ -z "$1" ] || __sourcestr=$1

  if [ -z "$__sourcestr" ]; then
    ERRCODE=2
    error "remote-rm requires a repository name or URL"
  fi

  dex-detect-sourcestr "$__sourcestr" || {
    [ -z "$1" ] && error "no match for $__sourcestr in sources.list"
    log "$__sourcestr not found, skipping removal..."
    return 1
  }

  for __source in "${__sources[@]}"; do
    read -r __source_name __source_url <<< "$__source"

    if $FORCE_FLAG; then
      rm -rf $DEX_HOME/checkouts/$__source_name 2>/dev/null
    elif [ -d $DEX_HOME/checkouts/$__source_name ]; then

      [ ! -w $DEX_HOME/checkouts/$__source_name  ] && {
        ERRCODE=126
        error "$DEX_HOME/checkouts/$__source_name" is not writable
      }

      is_dirty $DEX_HOME/checkouts/$__source_name ] && error \
        "$DEX_HOME/checkouts/$__source_name has local changes" \
        "pass --force to force removal, or reset/upstream your changes"

      rm -rf $DEX_HOME/checkouts/$__source_name
    fi

    sed_inplace $DEX_HOME/sources.list "/$__source_name /d"
    log "removed $__source_name"

  done
}
