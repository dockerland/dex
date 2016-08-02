#
# lib.d/function.sh for dex -*- shell-script -*-
#

dex-ping(){
  echo "pong"
}

error(){
  printf "\033[31m%s\n\033[0m" "$@" >&2
  exit 1
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