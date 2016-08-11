#
# lib.d/main_update.sh for dex -*- shell-script -*-
#


#@TODO support updating installed images

main_update(){

  local runstr="display_help"
  FORCE_FLAG=false

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do

      #@TODO migrate to argparsing (getopts?) to supports add --force
      case $1 in
        add|ls|pull|rm)   runstr="dex-remote-$1"
                          if [ $1 = "add" ]; then
                            arg_var "$2" REMOTE_NAME && shift
                            arg_var "$2" REMOTE_URL && shift
                          else
                            arg_var "$2" REMOTE_LOOKUP && shift
                          fi
                          ;;
        -f|--force)       FORCE_FLAG=true ;;
        -h|--help)        display_help ;;
        *)                unrecognized_arg "$1" ;;
      esac
      shift
    done
  fi

  dex-init
  $runstr
  exit $?

}

#dex-remote-ls
