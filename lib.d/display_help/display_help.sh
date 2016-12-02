display_help() {
  local cmd="$2"
  [ -z "$cmd" ] && {
    for fn in "${FUNCNAME[@]}"; do
      [ "main" = "${fn:0:4}" ] && {
        cmd="${fn//main_/}"
        break
      }
    done
  }

  is/fn "display_help_$cmd" || die/exception "missing helpfile for $cmd" \
    "is $cmd a valid command?"

  display_help_$cmd
  exit $1
}
