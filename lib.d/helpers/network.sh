#
# lib.d/helpers/network.sh for dex -*- shell-script -*-
#

# usage: fetch-url <url> <target-path>
fetch-url(){
  local WGET_PATH=${WGET_PATH:-wget}
  local CURL_PATH=${CURL_PATH:-curl}

  if ( type $WGET_PATH &>/dev/null ); then
    $WGET_PATH $1 -qO $2 || ( rm -rf $2 ; exit 1 )
  elif ( type $CURL_PATH &>/dev/null ); then
    $CURL_PATH -Lfso $2 $1
  else
    log "failed to fetch $2 from $1" "missing both curl and wget"
    return 2
  fi

  [ $? -eq 0 ] && return 0

  log "failed to fetch $2 from $1"
  return 126
}
