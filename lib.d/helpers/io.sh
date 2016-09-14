#
# lib.d/helpers/git.sh for dex -*- shell-script -*-
#

error(){
  [ -z "$1" ] && set -- "general exception. halting..."

  printf "\e[31m%b\n\e[0m" "$@" >&2
  exit ${__error_code:-1}
}

error_noent() {
  __error_code=127
  error "$@"
}

error_perms() {
  __error_code=126
  error "$@"
}

error_exception() {
  __error_code=2
  error "$@"
}


log(){
  printf "\e[33m%b\n\e[0m" "$@" >&2
}

prompt_echo() {
  while true; do
    echo
    # read always from /dev/tty, use `if [ -t 0 ]` upstream to avoid prompt
    read -r -p "  ${1:-input} : " INPUT </dev/tty
    [ -z "$INPUT" ] || { echo "$INPUT" ; return 0 ; }
    printf " \033[31m %s \n\033[0m" "invalid input"
  done
}

prompt_confirm() {
  while true; do
    echo
    # read always from /dev/tty, use `if [ -t 0 ]` upstream to avoid prompt
    read -r -n 1 -p "  ${1:-Continue?} [y/n]: " REPLY </dev/tty
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac
  done
}
