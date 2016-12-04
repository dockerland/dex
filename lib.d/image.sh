main_image(){
  local operand
  local list=()
  local quiet=false
  local all=false

  [ $# -eq 0 ] && display_help 1
  set -- $(args/normalize_flags_first "" "$@")
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        display_help  ;;
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
    io/shout "please provide an image to build"
    display_help 2
  }

  local repostr
  local Dockerfile
  local Dockerfiles
  for repostr in "$@"; do
    Dockerfiles=( $(dex/find-dockerfiles "$repostr") ) || {
      io/warn "skipping $repostr (unable to find a match in sources)"
      continue
    }

    for Dockerfile in "${Dockerfiles[@]}"; do
      repostr=$(dex/find-repostr-from-dockerfile $Dockerfile) || continue
      local repo=
      local image=
      local tag=
      IFS="/:" read repo image tag <<< "$repostr"

      (
        io/log "building \e[1m$repostr\e[21m ..."
        cd $(dirname $Dockerfile)
        Dockerfile=$(basename $Dockerfile)
        while [ -L "$Dockerfile" ]; do
          Dockerfile=$(readlink $Dockerfile)
        done

        # @TODO support templated [j2] builds as per buildchain
        io/comment "using $(pwd)/$Dockerfile"

        # deactivate machine so we execute local docker engine
        docker/deactivate_machine

        imagetag="$DEX_NAMESPACE/$image:$tag"
        random="$(LC_CTYPE=C tr -dc 'a-zA-Z0-9-_' < /dev/urandom | head -c10)" || true

        local flags=(
          "-t $imagetag"
          "-f $Dockerfile"
          "--label=\"org.dockerland.dex.namespace=$DEX_NAMESPACE\""
          "--label=\"org.dockerland.dex.runtime=$DEX_RUNTIME\""
          "--label=\"org.dockerland.dex.image=$image\""
          "--label=\"org.dockerland.dex.repo=$repo\""
          "--label=\"org.dockerland.dex.tag=$tag\""
        )

        $__pull && flags+=( "--pull" )
        is/in_file "$Dockerfile" "^ARG DEXBUILD_NOCACHE" && flags+=( "--build-arg DEXBUILD_NOCACHE=$random" )

        docker build ${flags[@]} . || {
          io/warn "failed building $Dockerfile"
          exit
        }

        # force re-create "build" container
        dex/image-build-container $imagetag true &>/dev/null || {
          io/warn "failed creating build container for $imagetag"
          exit
        }

        io/success "built \e[1m$repostr\e[21m"
      )

    done
  done
}

dex/image-build-container(){
  local image="$1"
  local recreate=${2:-false}
  local name=$(docker/safe_name "$image" "dexbuild")
  (
    exec &>/dev/null
    docker/deactivate_machine
    $recreate && docker rm --force $name
    docker inspect --type container $name || {
      docker run --entrypoint=false --name=$name $image
    }

    docker inspect -f "{{ .Id }}" --type container $name || exit 1
  )
}

dex/image-ls(){
  local repo
  local image
  local tag
  IFS="/:" read repo image tag <<< "$(dex/find-repostr $1)"

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
  local flags=()
  $__force && flags+=( "--force" )
  for image in $(quiet=true dex/image-ls "$@"); do
    $__force || prompt/confirm "remove $image ?" || continue
    for container in $(docker/local ps -q --filter ancestor=$image); do
      docker/local rm ${flags[@]} $container
    done
    docker/local rmi ${flags[@]} $image
  done
}
