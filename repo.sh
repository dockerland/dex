main_repo(){
  local operand
  local list=()

  [ $# -eq 0 ] && die/help 1
  set -- $(args/normalize_flags_first "" "$@")
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        die/help  ;;
      -d|--defaults)
        __defaults=true ;;
      -f|--force)
        __force=true ;;
      --)
        shift ; list=( "$@" ) ; break ;;
      -*)
        args/unknown "$1" "flag" ;;
      add|ls|pull|reset|rm)
        operand="dex/repo-$1" ;;
      *)
        [ -z "$operand" ] && args/unknown "$1"
        list+=( "$1" )
        ;;
    esac
    shift
  done

  shell/execfn "$operand" "${list[@]}"
}

dex/repo-add(){
  local repo="$1"
  local url="$2"
  [[ -z "$repo" || -z "$url" ]] && {
    p/shout "please provide a repo name and url"
    die/help 2
  }

  $__force && dex/repo-rm "$repo"

  dex/repo-exists "$repo" && {
    prompt/confirm "$repo already exists. overwrite?" || return 1
  }

  p/notice "adding \e[1m$repo\e[21m ..."

  file/interpolate "^$repo " "$repo $url" "$__sources"
  dex/repo-pull "$repo" || {
    __force=true dex/repo-rm "$repo"
    die/exception "failed to add $repo"
  }

  p/success "added \e[1m$repo\e[21m"
}

dex/repo-exists(){
  [ -n "$(dex/repo-ls $1)" ]
}

dex/repo-defaults(){
  if $DEX_NETWORK; then
    network/fetch "$__sources_url" "$__sources" && return
    p/warn "failed fetching $__sources"
  else
    p/warn "refusing to fetch \e[1m$__sources\e[21m" "networking is disabled"
  fi

  p/comment "loading build $SCRIPT_BUILD defaults..."
  cat << EOF > $__sources
#
# dex sources.list - $SCRIPT_BUILD defaults
#

core https://github.com/dockerland/dex-dockerfiles-core.git
extra https://github.com/dockerland/dex-dockerfiles-extra.git
EOF
}

dex/repo-reset(){
  p/notice "reseting $__sources"
  dex/repo-defaults || die/exception "unable to reset $__sources"

  local repo
  for repo in $(dex/repo-ls); do
    rm -rf $__checkouts/$repo
  done
  dex/repo-pull
  p/success "reset $__sources"
}

dex/repo-ls(){
  local name
  local url
  local junk
  local filters=( "$@" )
  local format="${__format:-\$name \$url}"
  local cmd="cat $__sources"
  $__defaults && cmd="network/print $__sources_url"

  $cmd | io/no-comments | while read name url junk ; do

    # skip malformed lines
    [[ -z "$name" || -z "$url" || -n "$junk" ]] && {
      p/warn "malformed line encountered in sources.list" "starting with: $name"
      continue
    }

    if [ ${#filters[@]} -gt 0 ]; then
      # skip lines not matching our filter
      is/matching "$name" "${filters[@]}" || continue
    fi

    eval "printf \"$format\n\""
  done
}

dex/repo-pull(){
  local repo
  local url
  local path
  # we use fd9 to allow for nested reads/prompts
  while read -u9 repo url ; do
    is/in_list "$repo" "${__pulled_repos[@]}" && continue
    pulled_repos+=( "$repo" )

    p/log "pulling $repo repository..."
    path="$__checkouts/$repo"

    ! $DEX_NETWORK && is/url "$url" && {
      p/warn "refusing to fetch \e[1m$repo\e[21m from $url" "networking is disabled"
      continue
    }

    if [ -d "$path" ]; then
      git/pull "$path" >&2 || return 1
    else
      git/clone "$url" "$path" >&2 || return 1
    fi


    p/success "pulled $repo repository"
  done 9< <(dex/repo-ls "$@")
}

dex/repo-rm(){
  local repo
  local path

  # we use fd3 to allow for nested reads/prompts
  for repo in $(__format="\$name" dex/repo-ls "$@"); do
    if ! $__force; then
      prompt/confirm "remove \e[1m$repo\e[21m from $__sources ?" || continue
    fi
    file/sed_inplace "/^$repo /d" "$__sources" 
    p/log "removing $repo from $__sources"

    path="$__checkouts/$repo"
    prompt/overwrite "$path" "remove checkout $path ?" && \
      p/log "removed checkout $path"
  done
}
