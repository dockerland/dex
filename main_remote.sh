#
# lib.d/main_remote.sh for dex -*- shell-script -*-
#

main_remote(){

  local reset=false
  local vars=()

  local runstr="vars_print"

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in
        ls)                dex-remote-ls ;;
        -h|--help)         display_help ;;
        *)                 unrecognized_arg "$1" ;;
      esac
      shift
    done
  fi

  $runstr
  exit $?
}

dex-remote-lookup(){
  exit
}


dex-remote-add(){
  exit
}

dex-remote-ls(){
  exit
}


dex-remote-pull(){
  exit
}

dex-remote-rm(){
  exit
}
