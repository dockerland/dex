#
# lib.d/main_vars.sh for dex -*- shell-script -*-
#

main_vars(){
  local operand="dex-vars-print"
  local operand_args=

  local reset=false
  local vars=()

  if [ $# -eq 0 ]; then
    display_help 2
  else
    set -- $(normalize_flags_first "" "$@")
    while [ $# -ne 0 ]; do
      case $1 in
        all)               vars=( "${DEX_VARS[@]}" ) ;;
        -d|--defaults)     operand="dex-vars-shellprint"
                           dex-vars-reset ;;
        -h|--help)         display_help ;;
        --)                shift ; operand_args="$@" ; break ;;
        -*)                unrecognized_flag $1 ;;
        *)                 vars+=( "$1" ) ;;
      esac
      shift
    done
  fi

  dex-vars-init ${vars[@]}
  $operand $operand_args ${vars[@]}
  exit $?
}
