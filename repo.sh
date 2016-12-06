main_repo(){
  local operand
  local list=()

  [ $# -eq 0 ] && display_help 1
  set -- $(args/normalize_flags_first "" "$@")
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        display_help  ;;
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
    io/shout "please provide a repo name and url"
    display_help 2
  }

  dex/repo-exists $repo && {
    prompt/confirm "$repo already exists. overwrite?" || return 1
    __force=true dex/repo-rm "$repo"
  }

  io/notice "adding \e[1m$repo\e[21m ..."
  file/interpolate "$__sources" "^$repo " "$repo $url"
  dex/repo-pull "$repo" || {
    __force=true dex/repo-rm "$repo"
    die/exception "failed to add $repo"
  }
  io/success "added \e[1m$repo\e[21m"
}

dex/repo-exists(){
  [ -n "$(dex/repo-ls $1)" ]
}

dex/repo-defaults(){
  if $DEX_NETWORK; then
    network/fetch "$__sources_url" "$__sources" && return
    io/warn "failed fetching $__sources"
  else
    io/warn "refusing to fetch \e[1m$__sources\e[21m" "networking is disabled"
  fi

  io/comment "loading build $SCRIPT_BUILD defaults..."
  cat << EOF > $__sources
#
# dex sources.list - $SCRIPT_BUILD defaults
#

core https://github.com/dockerland/dex-dockerfiles-core.git
extra https://github.com/dockerland/dex-dockerfiles-extra.git
EOF
}

dex/repo-reset(){
  io/notice "reseting $__sources"
  dex/repo-defaults || die/exception "unable to reset $__sources"

  local repo
  for repo in $(dex/repo-ls); do
    rm -rf $__checkouts/$repo
  done
  dex/repo-pull
  io/success "reset $__sources"
}

dex/repo-ls(){
  local name
  local url
  local junk
  local filter="$@"
  local format="${__format:-\$name \$url}"
  local cmd="cat $__sources"
  $__defaults && cmd="network/print $__sources_url"

  $cmd | while read name url junk ; do

    # skip blank, malformed, or comment lines
    [[ -z "$name" || -z "$url" || "#" = "$name" ]] && continue

    # skip lines not matching our filter
    [[ -n "$filter" && " $name " != *" $filter "* ]] && continue

    eval "printf \"$format\n\""
  done
}

dex/repo-pull(){
  local repo
  local url
  local path
  # we use fd9 to allow for nested reads/prompts
  while read -u9 repo url ; do\
    io/log "pulling $repo repository..."
    path="$__checkouts/$repo"

    ! $DEX_NETWORK && is/url "$url" && {
      io/warn "refusing to fetch \e[1m$repo\e[21m from $url" "networking is disabled"
      continue
    }

    if [ -d "$path" ]; then
      git/pull "$path" >&2 || return 1
    else
      git/clone "$url" "$path" >&2 || return 1
    fi
    io/success "pulled $repo repository"
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
    file/sed_inplace "$__sources" "/^$repo /d"
    io/log "removing $repo from $__sources"

    path="$__checkouts/$repo"
    prepare/overwrite "$path" "remove checkout $path ?" && \
      io/log "removed checkout $path"
  done
}
