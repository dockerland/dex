#!/usr/bin/env bash

#
# dex
#

main(){
  set -eo pipefail
  __cmd="main"
  readonly CWD="$( pwd -P )"
  readonly SCRIPT_CWD="$( cd $(dirname ${BASH_SOURCE[0]}) ; pwd -P )"
  readonly SCRIPT_BUILD="@BUILD@"
  readonly SCRIPT_ENTRYPOINT="$0 $@"
  readonly SCRIPT_VERSION="@VERSION@"

  dex/conf-init

  [ $# -eq 0 ] && display_help 2

  while [ $# -ne 0 ]; do
    case "$1" in
      -v|--version|version)
        log "Dex version $SCRIPT_VERSION build $SCRIPT_BUILD" ; exit ;;
      -h|--help)
        display_help ;;
      help)
        __cmd=${2:-$__cmd} ; display_help ;;
      conf|image|install|ls|repo|run)
        __cmd="$1" ; cli/fn main_"$@" ;;
      __fn)
        shift ; cli/fn "$@" ;;
      -*)
        unrecognized_flag "$1" ;;
      *)
        unrecognized_arg "$1" ;;
    esac
    shift
  done

  exit $?
}

#@start dev-mode
for helper in $(find $(dirname $0})/lib.d/ -type f -name "*.sh"); do
  . $helper
done
main "$@"
#@end dev-mode
