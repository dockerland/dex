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

  dex-setup
  $runstr
  exit $?
}

dex-remote-ls(){
  [ ! -e $DEX_HOME/sources.list ] && \
    ERRCODE=127 && error "missing $DEX_HOME/sources.list"

  cat $DEX_HOME/sources.list |
  while read name url junk ; do

    # skip blank, malformed, or comment lines
    if [ -z "$name" ] || [ -z "$url" ] || [[ $name = \#* ]]; then
      continue
    fi

    printf "$name\t$url\n"
  done
}



dex-remote-lookup(){
  exit
}


dex-remote-add(){
  exit
}



dex-remote-pull(){
  exit
}

dex-remote-rm(){
  exit
}
