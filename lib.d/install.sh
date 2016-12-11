main_install(){
  local operand="dex/install"
  local list=()
  local global=false

  [ $# -eq 0 ] && die/help 1
  set -- $(args/normalize_flags_first "" "$@")
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
  local imagetag
  local repo
  local image
  local tag

  (
    export DEX_NAMESPACE="${DEX_NAMESPACE}-install"
    for repostr in "$@"; do

      # ensure :latest if no image tag is passed
      repostr="$(dex/get-repostr "$repostr" "latest")" || {
        p/error "bad repostr ($repostr) passed to install"
        continue
      }


      dex/image-build "$repostr" || {
        p/warn "failed building $repostr"
        continue
      }

      for imagetag in "${__built_images[@]}"; do
        IFS="/:" read repo image tag <<< "${imagetag//$DEX_NAMESPACE\//}"
        p/log "installing $repo/$image:$tag ..."

        local bin="$DEX_BIN_DIR/${DEX_BIN_PREFIX}${image}-${tag}"
        prompt/overwrite "$bin" || continue

        echo "#!/usr/bin/env bash" > $bin
        declare -f docker/deactivate_machine >> $bin
        declare -f dex/image-build-container >> $bin
        declare -f docker/safe_name >> $bin
        declare -f get/gid_from_name >> $bin
        declare -f $DEX_RUNTIME-runtime >> $bin
        echo "__image=\"$imagetag\"" >> $bin
        echo "$runtimeFn \$@" >> $bin
        chmod +x $bin || {
          p/warn "unable to mark $bin executable"
          continue
        }

        p/notice "created $bin"

        dex/install-link "$bin" "${DEX_BIN_PREFIX}${image}" || continue
        $global && {
          dex/install-link "$bin" "${image}" || continue
        }

        p/success "installed $repo/$image:$tag"
      done
    done
  )
}

# dex-install-link <src> <dest>
dex/install-link(){
  local src="$1"
  local dest="$2"

  [ -e "$src" ] || return 127
  local file=$(basename $1)

  (
    cd "$(dirname $src)"
    prompt/overwrite "$dest" || exit
    ln -s "$(basename $src)" "$dest" || exit 2
    p/notice "linked $src to $dest"
  )

  return $?
}
