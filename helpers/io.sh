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

warn(){
  printf "\e[35m%b\n\e[0m" "$@" >&2
}

prompt_echo() {
  while true; do
    # read always from /dev/tty, use `if [ -t 0 ]` upstream to avoid prompt
    read -r -p "  ${1:-input} : " INPUT </dev/tty
    [ -z "$INPUT" ] || { echo "$INPUT" ; return 0 ; }
    printf "  \033[31m%s\033[0m\n" "invalid input" >&2
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
      *) printf "  \033[31m%s\033[0m\n" "invalid input" >&2
    esac
  done
}

# line_in_file : ensure a line exists in a file
###############################################
#
# usage: line_in_file "file" "match" "line"
#    ex: line_in_file "varsfile" "^VARNAME=.*$" "VARNAME=value"
#
line_in_file(){
  local delim=${4:-"|"}
  grep -q "$2" $1 2>/dev/null && sed_inplace $1 "s$delim$2$delim$3$delim" || echo $3 >> $1
}
