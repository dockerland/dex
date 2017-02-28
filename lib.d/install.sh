main_install(){
  local operand="dex/install"
  local list=()
  local global=false

  [ $# -eq 0 ] && die/help 1

  args/normalize_flags_first "" "$@"
  set -- "${__argv[@]}"
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        die/help  ;;
      -f|--force)
        __force=true ;;
      -g|--global)
        global=true ;;
      -p|--pull)
        __pull=true ;;
      --)
        shift ; list=( "$@" ) ; break ;;
      -*)
        args/unknown "$1" "flag" ;;
      *)
        list+=( "$1" )
        ;;
    esac
    shift
  done

  dex/get/engine-info >/dev/null
  shell/execfn "$operand" "${list[@]}"
}


dex/install(){
  [ $# -eq 0 ] && {
    p/shout "please provide an image to install"
    die/help 2
  }

  mkdir -p $DEX_BIN_DIR || die/perms "\$DEX_BIN_DIR $DEX_BIN_DIR is not writable"
  [ -w "$DEX_BIN_DIR" ] || die/perms "\$DEX_BIN_DIR $DEX_BIN_DIR is not writable"


  local repostr
  local repotag
  local repo
  local image
  local tag

  (
    export DEX_NAMESPACE="${DEX_NAMESPACE}-install"
    for repostr; do
      # ensure :latest if no image tag is passed
      repostr="$(dex/get-repostr "$repostr" "latest")" || {
        p/error "bad repostr ($repostr) passed to install"
        continue
      }

      __build_callback="dex/install/callback" dex/image-build "$repostr" || \
        die/exception "failed installing $repostr"
    done
  )

  shell/is/in_path "$DEX_BIN_DIR" || p/warn \
    "DEX_BIN_DIR is missing from your PATH!" \
    "add $DEX_BIN_DIR to your PATH to execute installed images from anywhere." \
    "if you prefer dex images over system installed commands," \
    "  prioritize DEX_BIN_DIR by placing at the beginning (leftmost) of PATH"
}


dex/install/callback(){
  local repotag="$1"
  IFS="/:" read repo image tag <<< "${repotag//$DEX_NAMESPACE\//}"
  p/log "installing $repo/$image:$tag ..."

  local bin="$DEX_BIN_DIR/${DEX_BIN_PREFIX}${image}-${tag}"
  prompt/overwrite "$bin" || return 1

  echo "#!/usr/bin/env bash" > $bin
  # runtime
  declare -f $DEX_RUNTIME-runtime >> $bin
  declare -f dex/get/reference-path >> $bin
  declare -f dex/run/mk-reference >> $bin

  # helpers
  declare -f docker/deactivate-machine >> $bin
  declare -f docker/get/safe-name >> $bin
  declare -f get/gid_from_name >> $bin
  declare -f die >> $bin
  declare -f io/cat >> $bin
  declare -f io/lowercase >> $bin
  declare -f is/absolute >> $bin
  declare -f is/any >> $bin
  declare -f is/cmd >> $bin
  declare -f is/in >> $bin
  declare -f p/error >> $bin
  declare -f p/blockquote >> $bin

  # image details
  echo "__repotag=\"$repotag\"" >> $bin
  echo "__name=\"$image\"" >> $bin
  echo "__tag=\"$tag\"" >> $bin
  echo "$DEX_RUNTIME-runtime \$@" >> $bin
  chmod +x $bin || {
    p/warn "unable to mark $bin executable"
    return 1
  }

  p/notice "created $bin"

  dex/install-link "$bin" "${DEX_BIN_PREFIX}${image}"
  $global && {
    dex/install-link "$bin" "${image}"
  }

  p/success "installed $repo/$image:$tag"
}

# dex-install-link <src> <dest>
dex/install-link(){
  local src="$1"
  local dest="$2"

  [ -e "$src" ] || return 127
  local file=$(basename $1)

  (
    set -e
    cd "$(dirname $src)"
    prompt/overwrite "$dest"
    ln -s "$(basename $src)" "$dest"
    p/notice "linked $src to $dest"
  )
}
