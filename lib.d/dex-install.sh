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

  for imgname in ${__built_images[@]}; do

    local api=$(docker inspect --format "{{ index .Config.Labels \"org.dockerland.dex.api\" }}" $imgname)
    local image=$(docker inspect --format "{{ index .Config.Labels \"org.dockerland.dex.image\" }}" $imgname)
    local bin="$DEX_BIN_DIR/${DEX_BIN_PREFIX}${image}"
    local gbin="$DEX_BIN_DIR/${image}"
    local runtimeFn="$api-runtime"

    if [ -z "$api" ]; then
      log "skipping $imgname -- org.dockerland.dex.api label not provided"
      continue
    elif [ -z "$image" ]; then
      log "skipping $imgname -- org.dockerland.dex.image label not provided"
      continue
    elif [ ! "$(type -t $runtimeFn)" = "function" ]; then
      log "skipping $imgname -- missing api runtime function ($runtimeFn)"
      continue
    elif [ -e $bin ] && ! $__force_flag; then
      log "skipping $image -- $bin exists" "  use --force to overwrite"
    else
      rm -rf $bin || error
      echo "#!/usr/bin/env bash" > $bin
      declare -f $runtimeFn >> $bin
      echo "__image=\"$imgname\"" >> $bin
      echo "$runtimeFn \$@" >> $bin
      chmod +x $bin || error_exception "unable to mark $bin executable"
      log "installed $bin"
    fi

    if $__global_flag ; then
      if [ -e $gbin ] || [ -L $gbin ]; then
        $__force_flag || {
          log "skipping global install -- $gbin exists" "  use --force to overwrite"
          continue
        }
        rm -rf $gbin || error
      fi

      (
        cd $DEX_BIN_DIR || exit 1
        ln -s ${DEX_BIN_PREFIX}${image} ${image} || exit 1
      ) || error_exception "unable to link global executable"

      log "installed $gbin"
    fi
  done

}
