#
# lib.d/dex-install.sh for dex -*- shell-script -*-
#

dex-install(){
  [ -z "$__imgstr" ] && error_exception \
    "dex-install requires an [repository/]<image>[:tag] imgstr"

  [ -d "$DEX_BIN_DIR" ] || error_noent "\$DEX_BIN_DIR $DEX_BIN_DIR is missing"
  [ -w "$DEX_BIN_DIR" ] || error_perms "\$DEX_BIN_DIR $DEX_BIN_DIR is not writable"

  local namespace="$DEX_NAMESPACE-install"

  if $__pull_flag; then
    dex-detect-imgstr $__imgstr || error "lookup failed to parse $__imgstr"
    $__pull_flag && dex-source-pull "$__source_match"
  fi

  dex-image-build $namespace || error_exception \
    "failed to build any images matching $__imgstr"

  log "* installing $__source_match/$__image_match images..."

  for imgname in ${__built_images[@]}; do

    local api=$(__local_docker inspect --type image --format "{{ index .Config.Labels \"org.dockerland.dex.api\" }}" $imgname)
    local image=$(__local_docker inspect --type image --format "{{ index .Config.Labels \"org.dockerland.dex.image\" }}" $imgname)
    local tag=$(__local_docker inspect --type image --format "{{ index .Config.Labels \"org.dockerland.dex.build-tag\" }}" $imgname)
    local bin="$DEX_BIN_DIR/${DEX_BIN_PREFIX}${image}-${tag}"
    local runtimeFn="$api-runtime"

    if [ -z "$api" ]; then
      log "skipping $imgname -- org.dockerland.dex.api label not provided"
      continue
    elif [ ! "$(type -t $runtimeFn)" = "function" ]; then
      log "skipping $imgname -- missing api runtime function ($runtimeFn)"
      continue
    elif [ -z "$image" ]; then
      log "skipping $imgname -- org.dockerland.dex.image label not provided"
      continue
    elif [ -z "$tag" ]; then
      log "skipping $imgname -- org.dockerland.dex.build-tag label not provided"
      continue
    else
      $__force_flag && rm -rf $bin

      if [ -e $bin ]; then
        log \
          "! $bin exists" \
          "  skipping $image installation" \
          "  use --force to overwrite"
      else
        echo "#!/usr/bin/env bash" > $bin
        declare -f __local_docker >> $bin
        declare -f __deactivate_machine >> $bin
        declare -f dex-image-build-container >> $bin
        declare -f docker_safe_name >> $bin
        declare -f get_group_id >> $bin
        declare -f $runtimeFn >> $bin
        echo "__image=\"$imgname\"" >> $bin
        echo "$runtimeFn \$@" >> $bin
        chmod +x $bin || error_exception "unable to mark $bin executable"
        log "+ installed $(basename $bin)"

        dex-install-link $bin ${DEX_BIN_PREFIX}${image} || \
          error_exception "unable to create link to $bin"
      fi
    fi

    if $__global_flag ; then
      dex-install-link $bin $image || \
        error_exception "unable to create global link to $bin"
    fi
  done
}

# dex-install-link <src> <dest>
dex-install-link(){
  [ -e $1 ] || error_exception "install-link: source $1 does not exist"
  local __src_dir=$(dirname $1)
  local __src_file=$(basename $1)
  (
    cd $__src_dir || exit 1

    $__force_flag && rm -rf $2

    if [ -e $2 ] || [ -L $2 ]; then
      log \
        "! $__src_dir/$2 exists" \
        "  skipped linking $2 to $__src_file" \
        "  use --force to overwrite"
    else
      ln -s $__src_file $2 || exit 1
      log "+ linked $__src_dir/$2 to $__src_file"
    fi
  )
  return $?
}
