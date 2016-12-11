# dex helpers

dex/find-dockerfiles(){
  local repostr="$1"
  local default_tag="$2"
  local repo
  local image
  local tag
  IFS="/:" read repo image tag <<< "$(dex/get-repostr $1)"

  local found=false
  local search_image
  local search_repo

  for search_repo in $(__format="\$name" dex/repo-ls $repo); do

    $__pull && dex/repo-pull "$search_repo"

    if [ -n "$image" ]; then
      local path="$__checkouts/$search_repo/dex-images/$image"
      find/dockerfiles "$path" "${tag:-$default_tag}" || continue
      found=true
    else
      for search_image in $(find/dirs "$__checkouts/$search_repo/dex-images"); do
        local path="$__checkouts/$search_repo/dex-images/$search_image"
        find/dockerfiles "$path" "${tag:-$default_tag}" || continue
        found=true
      done
    fi
  done

  $found && return 0
  return 127
}
