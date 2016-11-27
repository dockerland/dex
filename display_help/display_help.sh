display_help() {
  [ "$(type -t display_help_$__cmd)" = "function" ] || error \
    "missing helpfile for $__cmd" "is $__cmd a valid command?"

  display_help_$__cmd
  exit $1
}
