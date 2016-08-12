#
# lib.d/dex-vars.sh for dex -*- shell-script -*-
#

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


dex-vars-init(){
  while [ $# -ne 0 ]; do
    case $1 in
      DEX_API) eval "$1=\${$1:-v1}" ;;
      DEX_BIN_DIR) eval "$1=\${$1:-/usr/local/bin}" ;;
      DEX_BIN_PREFIX) eval "$1=\${$1:-d}" ;;
      DEX_HOME) eval "$1=\${$1:-~/.dex}" ;;
      DEX_NAMESPACE) eval "$1=\${$1:-dex/\$DEX_API}" ;;
      DEX_NETWORK) eval "$1=\${$1:-true}" ;;
      *) ERRCODE=127; error "$1 has no default configuration value" ;;
    esac
    shift
  done

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
  printf "# eval \$($ORIG_CMD)\n\n"
}
