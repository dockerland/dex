#
# lib.d/helpers/git.sh for dex -*- shell-script -*-
#

error(){
  printf "\e[31m%s\n\e[0m" "$@" >&2
  exit ${ERRCODE:-1}
}

log(){
  printf "\e[33m%s\n\e[0m" "$@" >&2
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

# sed_inplace : in place file substitution
############################################
#
# usage: sed_inplace "file" "sed substitution"
#    ex: sed_inplace "/tmp/file" "s/CLIENT_CODE/BA/g"
#
sed_inplace(){
  # linux
  local __sed="sed"

  if [[ $OSTYPE == darwin* ]]; then
    if $(type gsed >/dev/null 2>&1); then
      local __sed="gsed"
    elif $(type /usr/local/bin/sed >/dev/null 2>&1); then
      local __sed="/usr/local/bin/sed"
    else
      sed -i '' -E "$2" $1
      return
    fi
  fi

  $__sed -r -i "$2" $1
}
