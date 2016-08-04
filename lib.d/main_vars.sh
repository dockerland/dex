#
# lib.d/main_vars.sh for dex -*- shell-script -*-
#

main_vars(){

  local reset=false
  local vars=()

  local runstr="vars_print"

  if [ $# -eq 0 ]; then
    display_help 2
  else
    while [ $# -ne 0 ]; do
      case $1 in
        all)               vars=( "${DEX_VARS[@]}" ) ;;
        -d|--defaults)     runstr="vars_print_export"
                           vars_reset ${DEX_VARS[@]} ;;
        -h|--help)         display_help ;;
        *)                 vars+=$1 ;;
      esac
      shift
    done
  fi

  vars_load ${vars[@]}
  $runstr ${vars[@]}
  exit $?
}
