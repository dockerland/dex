#
# lib.d/function.sh for dex -*- shell-script -*-
#

dex-ping(){
  echo "pong"
  exit 0
}

error(){
  printf "\033[31m%s\n\033[0m" "$@" >&2
  exit ${ERRCODE:-1}
}

prompt_confirm() {
  while true; do
    echo
    read -r -n 1 -p "  ${1:-Continue?} [y/n]: " REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac
  done
}

unrecognized_arg(){

  if [ $CMD = "main" ]; then
    printf "\n\n$1 is an unrecognized command\n\n"
  else
    printf "\n\n$1 is an unrecognized argument to the $CMD command.\n\n"
  fi

  display_help 127

}

vars_load(){
  while [ $# -ne 0 ]; do
    case $1 in
      DEX_HOME) DEX_HOME=${DEX_HOME:-~/.dex} ;;
      DEX_BINDIR) DEX_BINDIR=${DEX_BINDIR:-/usr/local/bin} ;;
      DEX_PREFIX) DEX_PREFIX=${DEX_PREFIX:-'d'} ;;
      *) ERRCODE=127; error "$1 has no default configuration value" ;;
    esac
    shift
  done
}

vars_reset(){
  while [ $# -ne 0 ]; do
    unset $1
    shift
  done
}

vars_print(){
  while [ $# -ne 0 ]; do
    eval "printf \"$1=\$$1\n\""
    shift
  done
}

vars_print_export(){
  # TODO -- shell detection for fish|export
  while [ $# -ne 0 ]; do
    eval "printf \"export $1=\$$1\n\""
    shift
  done

  printf "# Run this command to configure your shell: \n"
  printf "# eval \$($ORIG_CMD)\n\n"
}
