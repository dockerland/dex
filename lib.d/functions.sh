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

# usage: clone_or_pull <repo-path-or-url> <destination> <force boolean>
# @TODO: respect DEX_NETWORK setting?
clone_or_pull(){
  if [ -d $2 ]; then
    # pull
    (
      cd $2
      $3 && git reset --hard HEAD
      git pull
    ) || {
      log "error pulling changes from git"
      return 1
    }

  else
    # clone

    #@TODO support reference repository
    #  [detect if local repo is a bare repo -- but how to find remote?]

    local SHARED_FLAG=

    [ -w $(dirname $2) ] || {
      log "destination directory not writable"
      return 126
    }

    if [[ $1 == /* ]]; then
      # perform a shared clone (URL is a local path starting with '/...' )
      [ -d $1/.git ] || {
        log "$1 is not a path to a local git repository"
        return 1
      }
      SHARED_FLAG="--shared"
    fi

    git clone $SHARED_FLAG $1 $2 || {
      log "error cloning $1 to $2"
      return 1
    }
  fi

  return 0
}

# checks git working copy.
# return 1 if clean (not dirty), 0 if dirty (changes exist)
is-dirty(){

  [ -d $1/.git ] || {
    log "$1 is not a git repository. continuing..."
    return 1
  }

  (
    set -e
    cd $1
    [ ! -z "$(git status -uno --porcelain)" ]
  )
  return $?
}

runfunc(){
  [ "$(type -t $1)" = "function" ] || error \
    "$1 is not a valid runfunc target"

  $@
}

# usage:  arg_var <arg> <variiable>
# assigns a variable from an argument if <arg> is not a flag, else clears it
arg_var(){
  if [[  $1 == -* ]]; then
    eval "$2="
    return 1
  else
    eval "$2=\"$1\""
    return 0
  fi
}


unrecognized_arg(){

  if [ $CMD = "main" ]; then
    printf "\n\n$1 is an unrecognized command\n\n"
  else
    printf "\n\n$1 is an unrecognized argument to the $CMD command.\n\n"
  fi

  display_help 127
}


# sed_inplace : in place file substitution
############################################
#
# usage: sed_inplace "file" "sed substitution"
#    ex: sed_inplace "/tmp/file" "s/CLIENT_CODE/BA/g"
#

sed_inplace(){
  # linux
  local SED_CMD="sed"

  if [[ $OSTYPE == darwin* ]]; then
    if $(type gsed >/dev/null 2>&1); then
      local SED_CMD="gsed"
    elif $(type /usr/local/bin/sed >/dev/null 2>&1); then
      local SED_CMD="/usr/local/bin/sed"
    else
      sed -i '' -E "$2" $1
      return
    fi
  fi

  $SED_CMD -r -i "$2" $1
}


vars_load(){
  while [ $# -ne 0 ]; do
    case $1 in
      DEX_HOME) eval "$1=\${$1:-~/.dex}" ;;
      DEX_BIN_DIR) eval "$1=\${$1:-/usr/local/bin}" ;;
      DEX_BIN_PREFIX) eval "$1=\${$1:-d}" ;;
      DEX_NETWORK) eval "$1=\${$1:-true}" ;;
      DEX_API) eval "$1=\${$1:-v1}" ;;
      DEX_TAG_PREFIX) eval "$1=\${$1:-dex/\$DEX_API}" ;;
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

dex-sources-fetch(){

  dex-fetch "https://raw.githubusercontent.com/dockerland/dex/briceburg/wonky/sources.list" $DEX_HOME/sources.list.fetched

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

dex-sources-cat(){
  cat <<-EOF
#
# dex sources.list
#

core git@github.com:dockerland/dex-dockerfiles-core.git
extra git@github.com:dockerland/dex-dockerfiles-extra.git

EOF
}

# dex-sources-lookup <name|url>
# @returns 1 if not found
# @returns 0 if found, and sets DEX_REMOTE=<resolved-name>
dex-sources-lookup(){
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

dex-setup(){
  ERRCODE=126

  [ -d $DEX_HOME ] || mkdir -p $DEX_HOME || error \
    "could not create working directory \$DEX_HOME"

  [ -d $DEX_HOME/checkouts ] || mkdir -p $DEX_HOME/checkouts || error \
    "could not create checkout directory under \$DEX_HOME"

  ( type docker >/dev/null 2>&1 ) || error \
    "dex requires docker"

  [ -e $DEX_HOME/sources.list ] || dex-sources-fetch

  for path in $DEX_HOME $DEX_HOME/checkouts $DEX_HOME/sources.list; do
    [ -w $path ] || error "$path is not writable"
  done

  ERRCODE=1
  return 0
}

# dex-lookup-parse outputs paths to matching dockerfiles
#  optionally accepts <[repo/]image|*> lookup to set DEX_REMOTE_*
dex-lookup-dockerfiles(){
  [ -z "$1" ] || { dex-lookup-parse $1 || error "lookup failed to parse $1" ; }

  for repo_dir in $(ls -d $DEX_HOME/checkouts/$DEX_REMOTE 2>/dev/null); do
    for image_dir in $(ls -d $repo_dir/images/$DEX_REMOTE_IMAGESTR 2>/dev/null); do
      if [ "$DEX_REMOTE_IMAGETAG" = "latest" ]; then
        dockerfile="Dockerfile"
      else
        dockerfile="Dockerfile-$DEX_REMOTE_IMAGETAG"
      fi
      [ -e $image_dir/$dockerfile ] && echo $image_dir/$dockerfile
    done
  done
}

# dex-lookup-parse accepts <[repo/]image|*> and sets
#  DEX_REMOTE (checkout source, e.g. 'core')
#  DEX_IMAGESTR (image name, e.g. 'alpine')
#  DEX_REMOTE_IMAGETAG (image tag, e.g. 'latest')
dex-lookup-parse(){
  DEX_REMOTE=
  DEX_REMOTE_IMAGESTR=

  [ -z "$1" ] && return 1

  local remote
  local imagestr
  local tag
  local debug=${2:-false}

  IFS='/'
  read -r remote imagestr <<< "$1"
  unset IFS

  if [ -z "$imagestr" ]; then
    DEX_REMOTE="*"
    DEX_REMOTE_IMAGESTR="$1"
  else
    DEX_REMOTE="$remote"
    DEX_REMOTE_IMAGESTR="$imagestr"

    if [ ! -d $DEX_HOME/checkouts/$DEX_REMOTE ]; then
      log "warning, $remote is not checked out" \
      "  has it been added with dex remote?"
    fi
  fi

  IFS=':'
  read -r image tag <<< "$DEX_REMOTE_IMAGESTR"
  unset IFS

  if [ -z "$tag" ]; then
    DEX_REMOTE_IMAGETAG="latest"
  else
    DEX_REMOTE_IMAGESTR="$image"
    DEX_REMOTE_IMAGETAG="$tag"
  fi

  # if $2 is true, echo lines for evaluation
  $debug && printf "DEX_REMOTE=$DEX_REMOTE\nDEX_REMOTE_IMAGESTR=$DEX_REMOTE_IMAGESTR\nDEX_REMOTE_IMAGETAG=$DEX_REMOTE_IMAGETAG\n"

  return 0
}
