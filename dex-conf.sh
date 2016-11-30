dex-vars-print(){
  while [ $# -ne 0 ]; do
    eval "printf \"$1=\$$1\n\""
    shift
  done
}


dex-vars-reset(){
  for var in "${DEX_VARS[@]}"; do
    unset $var
  done
}




# DEX_BIN_DIR: location where dex installs : /usr/local/bin
# DEX_BIN_PREFIX: prefix of dexecutabls : d
# DEX_HOME: dex workspace : ~/.dex
# DEX_NAMESPACE: prefix used when tagging image builds : dex/v1
# DEX_NETWORK: enables network fetching : true
# DEX_RUNTIME: runtime api version: v1
dex/conf-init(){
  DEX_RUNTIME=${DEX_RUNTIME:-v1}
  DEX_BIN_DIR=${DEX_BIN_DIR:-~/bin}
  DEX_BIN_PREFIX=${DEX_BIN_PREFIX:--d}
  DEX_HOME=${DEX_HOME:-~/dex}
  DEX_NAMESPACE=${DEX_NAMESPACE:-dex/$DEX_RUNTIME}
  DEX_NETWORK=${DEX_NETWORK:-true}

  # bootstrap internal vars
  __checkouts=$DEX_HOME/checkouts
}




dex-vars-shellprint(){
  # @TODO -- shell detection for fish|export
  while [ $# -ne 0 ]; do
    eval "printf \"export $1=\$$1\n\""
    shift
  done

  printf "# Run this command to configure your shell: \n"
  printf "# eval \$($SCRIPT_ENTRYPOINT)\n\n"
}
