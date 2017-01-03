main_image(){
  local operand
  local list=()
  local quiet=false
  local all=false
  local format

  [ $# -eq 0 ] && die/help 1
  set -- $(args/normalize "" "$@")
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
        die/help  ;;
      -a|--all)
        all=true ;;
      -f|--force)
        __force=true ;;
      --format)
        format="$2" ; shift ;;
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

  local success=false
  local repostr
  local Dockerfile
  local Dockerfiles
  for repostr; do
    local repo=
    local image=
    local tag=
    IFS="/:" read repo image tag <<< "$repostr"

    Dockerfiles=( $(dex/find-dockerfiles "$repostr" "latest") ) || {
      if [ -z "$repo" ]; then
        p/warn "$repostr is missing from repository checkouts"
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

        random="$(LC_CTYPE=C tr -dc 'a-zA-Z0-9-_' < /dev/urandom | head -c10)" || true
        local flags=(
          "-t $__image"
          "-f $Dockerfile"
          "--label=org.dockerland.dex.namespace=$DEX_NAMESPACE"
          "--label=org.dockerland.dex.runtime=$DEX_RUNTIME"
          "--label=org.dockerland.dex.image=$image"
          "--label=org.dockerland.dex.repo=$repo"
          "--label=org.dockerland.dex.tag=$tag"
        )

        $__pull && $DEX_NETWORK && flags+=( "--pull" )
        is/in_file "^ARG DEXBUILD_NOCACHE" "$Dockerfile" && flags+=( "--build-arg DEXBUILD_NOCACHE=$random" )

        docker/local build ${flags[@]} . || exit 1
      ) || {
        p/error "failed building $Dockerfile"
        continue
      }

      # force re-recreation of "reference" directory used by runtime
      local reference_path="$(dex/get/reference-path $__image)"
      [ -e "$reference_path" ] && rm -rf "$reference_path"

      success=true
      p/success "built \e[1m$repostr\e[21m"

      [ -z "$__build_callback" ] || $__build_callback "$__image"
    done
  done

  $success
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
  [ -n "$format" ] && flags+=( "--format $format" )
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

    for container in $(docker/local ps -q --filter ancestor=$image); do
      docker/local rm ${flags[@]} $container
    done

    docker/local rmi ${flags[@]} $image
  done
}
