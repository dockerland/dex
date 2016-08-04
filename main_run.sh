#
# lib.d/main_run.sh for dex -*- shell-script -*-
#

main_run(){

  local runstr="display_help"

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in
        -h|--help)         display_help ;;
        *)                 unrecognized_arg "$1" ;;
      esac
      shift
    done
  fi

  $runstr
  exit $?

}
