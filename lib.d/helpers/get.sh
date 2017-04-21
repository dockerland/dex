# dex helpers
# return first found built image matching repostr
dex/get-image(){
  local repo
  local image
  local tag
  IFS="/:" read repo image tag <<< "$(dex/get-repostr "$1")"

  [ -z "$image" ] && return 2

  local flags=(
    "-q"
    "--filter dangling=false"
    "--filter label=org.dockerland.dex.namespace=$DEX_NAMESPACE"
    "--filter label=org.dockerland.dex.image=$image"
  )

  [ -n "$repo" ] && flags+=( "--filter label=org.dockerland.dex.repo=$repo" )
  [ -n "$tag" ] && flags+=( "--filter label=org.dockerland.dex.tag=$tag" )

  docker/local images ${flags[@]} | head -n1
}

# normalizes a repostr
dex/get-repostr(){
  local repostr="$1"
  local default_tag="$2"
  local imagestr
  local repo
  local image
  local tag
  local junk

  IFS="/" read repo imagestr junk <<< "$repostr"

  [ -n "$junk" ] && {
    p/warn "malformed repostr $repostr"
    return 2
  }

  [[ -z "$imagestr" && "$repostr" != "$repo/" ]] && {
    # no repo was specified.
    imagestr="$repo"
    repo=
  }

  IFS=":" read image tag junk <<< "$imagestr"

  [ -n "$junk" ] && {
    p/warn "malformed imagestr $imagestr"
    return 2
  }

  # tag images with default tag if image is specified and tag is empty
  [[ -z "$tag" && -n "$image" ]] && tag="$default_tag"

  echo "$repo/$image:$tag"
}

# given a Dockerfile path in checkouts, print a fully qualified repostr
dex/get-repostr-from-dockerfile(){
  local Dockerfile="$1"
  local tag=$(docker/get/dockerfile-tag $Dockerfile)
  local repo=${Dockerfile//$__checkouts\//}
  repo=${repo%%/*}
  local image=${Dockerfile//$__checkouts\/$repo\/dex-images\//}
  image=${image%%/*}

  [[ -z "$repo" || -z "$image" || -z "$tag" ]] && {
    p/warn "failed determining repostr from $Dockerfile"
    return 1
  }

  echo "$repo/$image:$tag"
}


# output path containing reference files from an image/repotag
dex/get/reference-path(){
  echo "$DEX_HOME/references/$(docker/get/safe-name "$1")"
}

dex/get/engine-info(){
  docker/local version || die "dex failed communicating with docker. is it running? do you have access to its socket?" "executing 'docker version' must succeed"
}
