#!/usr/bin/env bash

#
# dex
#

main(){
  set -eo pipefail
  readonly CWD="$( pwd -P )"
  [ -z "${BASH_SOURCE[0]}" ] || readonly SCRIPT_CWD="$( cd $(dirname ${BASH_SOURCE[0]}) ; pwd -P )"
  readonly SCRIPT_BUILD="@BUILD@"
  readonly SCRIPT_ENTRYPOINT="$0 $@"
  readonly SCRIPT_VERSION="@VERSION@"

  dex/conf-init

  [ $# -eq 0 ] && die/help 1

  while [ $# -ne 0 ]; do
    case "$1" in
      -v|--version|version)
        echo "Dex version $SCRIPT_VERSION build $SCRIPT_BUILD" ; exit ;;
      -h|--help)
        die/help ;;
      help)
        is/fn "p/help_$2" || die "missing help for $2"
        p/help_$2 ; exit ;;
      conf|image|install|ls|ps|repo|run)
        shell/execfn main_"$@" ;;
      runfunc)
        shift ; shell/execfn "$@" ;;
      -*)
        args/unknown "$1" "flag" ;;
      *)
        args/unknown "$1" "command" ;;
    esac
    shift
  done
}

#@start dev-mode
for helper in $(find $(dirname $0})/lib.d/ -type f -name "*.sh"); do
  . $helper
done
main "$@"
#@end dev-mode
