#
# lib.d/helpers/network.sh for dex -*- shell-script -*-
#

# usage: fetch-url <url> <target-path>
fetch-url(){
  local WGET_PATH=${WGET_PATH:-wget}
  local CURL_PATH=${CURL_PATH:-curl}

  if ( type $WGET_PATH >/dev/null 2>&1 ); then
    $WGET_PATH $1 -O $2 || ( rm -rf $2 ; exit 1 ) 
  elif ( type $CURL_PATH >/dev/null 2>&1 ); then
    $CURL_PATH -Lfo $2 $1
  else
    log "failed to fetch $2 from $1" "missing curl and wget"
    return 2
  fi

  [ $? -eq 0 ] && \
    log "fetched fetch $2 from $1" && \
    return 0

  log "failed to fetch $2 from $1"
  return 126
}
