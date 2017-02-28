# dex helpers

dex/find-dockerfiles(){
  local repostr="$1"
  local default_tag="$2"
  local repo
  local image
  local tag
  IFS="/:" read repo image tag <<< "$(dex/get-repostr "$repostr")"

  local found=false
  local search_image
  local search_repo

  for search_repo in $(__format="\$name" dex/repo-ls $repo); do

    $__pull && dex/repo-pull "$search_repo"

    for search_image in $(find/dirs "$__checkouts/$search_repo/dex-images" "$image" 2>/dev/null); do
      local path="$__checkouts/$search_repo/dex-images/$search_image"
      docker/find/dockerfiles "$path" "${tag:-$default_tag}" || {
        [ -n "$tag" ] || docker/find/dockerfiles "$path" || continue
        # ^^^ if not images were found using the default tag, try without a tag.
        # allows soft-limiting, e.g. if installing all images from a repo,
        # attempt :latest first, then install all variants if missing :latest
        #
      }
      found=true
    done
  done

  $found
}
