#
# lib.d/helpers/git.sh for dex -*- shell-script -*-
#

# usage: clone_or_pull <repo-path-or-url> <destination> <force boolean>
clone_or_pull(){
  local force=${3:-false}
  if [ -d $2 ]; then
    # pull
    (
      cd $2
      $force && git reset --hard HEAD
      git pull
    ) || {
      log "error pulling changes from git"
      return 1
    }
  else
    # clone

    #@TODO support reference repository
    #  [detect if local repo is a bare repo -- but how to find remote?]

    local SHARED_FLAG=

    [ -w $(dirname $2) ] || {
      log "destination directory not writable"
      return 126
    }

    if [[ $1 == /* ]]; then
      # perform a shared clone (URL is a local path starting with '/...' )
      [ -d $1/.git ] || {
        log "$1 is not a path to a local git repository"
        return 1
      }
      SHARED_FLAG="--shared"
    fi

    git clone $SHARED_FLAG $1 $2 || {
      log "error cloning $1 to $2"
      return 1
    }
  fi

  return 0
}


# checks git working copy.
# return 1 if clean (not dirty), 0 if dirty (changes exist)
is_dirty(){

  [ -d $1/.git ] || {
    log "$1 is not a git repository. continuing..."
    return 1
  }

  (
    set -e
    cd $1
    [ ! -z "$(git status -uno --porcelain)" ]
  )
  return $?
}
