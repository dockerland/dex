#
# lib.d/main_vars.sh for dex -*- shell-script -*-
#

main_vars(){

  local reset=false
  local vars=()

  local runstr="dex-vars-print"

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in
        all)               vars=( "${DEX_VARS[@]}" ) ;;
        -d|--defaults)     runstr="dex-vars-shellprint"
                           dex-vars-reset ;;
        -h|--help)         display_help ;;
        *)                 vars+=$1 ;;
      esac
      shift
    done
  fi

  dex-vars-init ${vars[@]}
  $runstr ${vars[@]}
  exit $?
}
