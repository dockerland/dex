#
# lib.d/dex-remote.sh for dex -*- shell-script -*-
#

dex-source-add(){
  if [ -z "$__lookup_name" ] || [ -z "$__lookup_url" ]; then
    ERRCODE=2
    error "source-add requires NAME and URL"
  fi

  if $__force_flag; then
    dex-source-rm "$__lookup_name"
    dex-source-rm "$__lookup_url"
  elif dex-detect-sourcestr "$__lookup_name" || dex-detect-sourcestr "$__lookup_url" ; then
    ERRCODE=2
    error "refusing to add $__lookup_name -- duplicate name or url"
  fi

  [ -e $DEX_HOME/checkouts/$__lookup_name ] && {
    ERRCODE=2
    error "refusing to add $__lookup_name" \
      "checkout $DEX_HOME/checkouts/$__lookup_name already exists" \
      "use --force flag to overwrite"
  }

  clone_or_pull "$__lookup_url" "$DEX_HOME/checkouts/$__lookup_name" || error \
    "unable to add respository"

  echo "$__lookup_name $__lookup_url" >> $DEX_HOME/sources.list || error \
    "unable to update sources.list"

  log "$__lookup_name added"
}

dex-source-ls(){
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

# dex-source-pull updates a source checkout. updates all sources if * is passed.
# usage: dex-source-pull <repostr|*>
#    ex: dex-source-pull core
#    ex: dex-source-pull git@github.com:dockerland/dex-dockerfiles-core.git
#    ex: dex-remote pull *
dex-source-pull(){
  [ -z "$1" ] || __sourcestr="$1"

  if [ -z "$__sourcestr" ]; then
    ERRCODE=2
    error "source-pull requires a repository name or URL"
  fi

  dex-detect-sourcestr "$__sourcestr" || {
    [ -z "$1" ] && error "no match for $__sourcestr in sources.list"
    log "$__sourcestr not found, skipping pull..."
    return 1
  }

  for __source in "${__sources[@]}"; do
    read -r __source_name __source_url <<< "$__source"

    if ! $__force_flag && is_dirty $__checkouts/$__source_name ]; then
      error "$DEX_HOME/checkouts/$__source_name has local changes" \
      "pass --force to force update, or reset/upstream your changes"
    fi

    ! $DEX_NETWORK && [[ ! "$__source_url" == /* ]] && {
      log "skipping $__source_name -- networking disabled"
      continue
    }


    clone_or_pull $__source_url $__checkouts/$__source_name $__force_flag || \
      error "error pulling $__source_name"

    log "$__source_name updated"
  done
}


dex-source-rm(){
  [ -z "$1" ] || __sourcestr=$1

  if [ -z "$__sourcestr" ]; then
    ERRCODE=2
    error "source-rm requires a repository name or URL"
  fi

  dex-detect-sourcestr "$__sourcestr" || {
    [ -z "$1" ] && error "no match for $__sourcestr in sources.list"
    log "$__sourcestr not found, skipping removal..."
    return 1
  }

  for __source in "${__sources[@]}"; do
    read -r __source_name __source_url <<< "$__source"

    if $__force_flag; then
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
