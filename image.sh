main_image(){
  local operand
  local list=()
  local quiet=false
  local all=false

  [ $# -eq 0 ] && die/help 1
  set -- $(args/normalize_flags_first "" "$@")
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        die/help  ;;
      -a|--all)
        all=true ;;
      -f|--force)
        __force=true ;;
      -p|--pull)
        __pull=true ;;
      -q|--quiet)
        quiet=true ;;
      --)
        shift ; list=( "$@" ) ; break ;;
      -*)
        args/unknown "$1" "flag" ;;
      build|ls|rm)
        operand="dex/image-$1" ;;
      *)
        [ -z "$operand" ] && args/unknown "$1"
        list+=( "$1" )
        ;;
    esac
    shift
  done
  shell/execfn "$operand" "${list[@]}"
}

dex/image-build(){
  [ $# -eq 0 ] && {
    p/shout "please provide an image to build"
    die/help 2
  }

  __built_images=()
  local repostr
  local Dockerfile
  local Dockerfiles
  for repostr in "$@"; do
    local repo=
    local image=
    local tag=
    IFS="/:" read repo image tag <<< "$repostr"

    Dockerfiles=( $(dex/find-dockerfiles "$repostr") ) || {
      if [ -z "$repo" ]; then
        p/warn "$repostr is missing from all repository checkouts"
      else
        p/warn "$repostr is missing from the \e[1m$repo\e[21m repository"
      fi
      continue
    }

    for Dockerfile in "${Dockerfiles[@]}"; do
      repostr=$(dex/get-repostr-from-dockerfile $Dockerfile) || continue
      local repo=
      local image=
      local tag=
      IFS="/:" read repo image tag <<< "$repostr"

      p/log "building \e[1m$repostr\e[21m ..."
      __image="$DEX_NAMESPACE/$repo/$image:$tag"

      (
        exec >&2
        cd $(dirname $Dockerfile) || exit 1
        Dockerfile=$(basename $Dockerfile)
        while [ -L "$Dockerfile" ]; do
          Dockerfile=$(readlink $Dockerfile)
        done

        # @TODO support templated [j2] builds as per buildchain
        p/comment "using $(pwd)/$Dockerfile"

        # deactivate machine so we execute local docker engine
        docker/deactivate-machine

        random="$(LC_CTYPE=C tr -dc 'a-zA-Z0-9-_' < /dev/urandom | head -c10)" || true
        local flags=(
          "-t $__image"
          "-f $Dockerfile"
          "--label=\"org.dockerland.dex.namespace=$DEX_NAMESPACE\""
          "--label=\"org.dockerland.dex.runtime=$DEX_RUNTIME\""
          "--label=\"org.dockerland.dex.image=$image\""
          "--label=\"org.dockerland.dex.repo=$repo\""
          "--label=\"org.dockerland.dex.tag=$tag\""
        )

        $__pull && flags+=( "--pull" )
        is/in_file "^ARG DEXBUILD_NOCACHE" "$Dockerfile" && flags+=( "--build-arg DEXBUILD_NOCACHE=$random" )

        docker build ${flags[@]} . || exit 1

        # force re-create "build" container
        dex/image-build-container $__image true &>/dev/null || {
          p/warn "failed creating build container for $__image"
          exit 1
        }
      ) || {
        p/error "failed building $Dockerfile"
        continue
      }

      __built_images+=( "$__image" )
      p/success "built \e[1m$repostr\e[21m"

    done
  done

  [ ${#__built_images[@]} -gt 0 ]
}

dex/image-build-container(){
  local image="$1"
  local recreate=${2:-false}
  local name=$(docker/get/safe-name "$image" "dexbuild")
  (
    exec &>/dev/null
    docker/deactivate-machine
    $recreate && docker rm --force $name
    docker inspect --type container $name || {
      docker run --label org.dockerland.dex.dexbuild=yes --entrypoint=false --name=$name $image
    }

    docker inspect -f "{{ .Id }}" --type container $name || exit 1
  )
}

dex/image-ls(){
  local repo
  local image
  local tag
  IFS="/:" read repo image tag <<< "$(dex/get-repostr $1)"

  if $all; then
    local flags=(
      "--filter=label=org.dockerland.dex.namespace"
    )
  else
    local flags=(
      "--filter=\"label=org.dockerland.dex.namespace=$DEX_NAMESPACE\""
    )
  fi
  [ -n "$image" ] && flags+=( "--filter=label=org.dockerland.dex.image=$image" )
  [ -n "$repo" ] && flags+=( "--filter=label=org.dockerland.dex.repo=$repo" )
  [ -n "$tag" ] && flags+=( "--filter=label=org.dockerland.dex.tag=$tag" )
  $quiet && flags+=( "-q" )

  docker/local images ${flags[@]}
}


dex/image-rm(){
  local image
  local container
  local build_container
  local repotag
  local flags=()
  $__force && flags+=( "--force" )
  for image in $(quiet=true dex/image-ls "$@"); do
    $__force || prompt/confirm "remove $image ?" || continue

    # first lets remove the 'build' container. we need sha => name
    repotag="$(docker/get/repotag "$image")" && {
      build_container="$(docker/get/safe-name "$repotag" "dexbuild")"
      docker/local rm --force "$build_container" || true
    }

    # next, lets remove any containers using this image as an ancestor
    for container in $(docker/local ps -q --filter ancestor=$image); do
      docker/local rm ${flags[@]} $container
    done

    # finally, remove image
    docker/local rmi ${flags[@]} $image
  done
}
