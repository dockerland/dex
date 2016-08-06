#
# lib.d/main_remote.sh for dex -*- shell-script -*-
#

main_remote(){

  local runstr="display_help"

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in
        add)              arg_var $2 REMOTE_NAME && shift
                          arg_var $2 REMOTE_URL && shift
                          runstr="dex-remote-add" ;;
        ls)               arg_var $2 REMOTE_NAME && shift
                          arg_var $2 REMOTE_URL && shift
                          runstr="dex-remote-ls" ;;
        -h|--help)        display_help ;;
        *)                unrecognized_arg "$1" ;;
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
