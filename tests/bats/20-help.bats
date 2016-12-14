#!/usr/bin/env bats

#
# 20 - cli tests
#

load app

@test "help prints, app exits with status code 1 when no arguments are passed" {
  run $APP
  [ $status -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "help prints, warns on invalid flags and arguments" {
  run $APP invalid-argument
  [ $status -eq 10 ]
  [[ "$output" == *"unrecognized command"* ]]

  run $APP --invalid-flag
  [ $status -eq 10 ]
  [[ "$output" == *"unrecognized flag"* ]]
}

#
# subcommands...
#

@test "help is provided for all dex commands" {
  for cmd in ${APP_CMDS[@]} ; do
    echo "testing $cmd"
    run $APP help $cmd
    [ $status -eq 0 ]
  done
}

@test "help is provided whenever -h or --help flags are passed to a command" {
  for cmd in ${APP_CMDS[@]} ; do
    echo "testing $cmd"
    run $APP $cmd -h
    [ $status -eq 0 ]
    [ -n "$output" ]
    diff <($APP $cmd -h) <($APP help $cmd)
    diff <($APP $cmd --help) <($APP help $cmd)
  done
}

@test "help exits with status code 1 when no arguments are passed to a command" {
  for cmd in ${APP_CMDS[@]} ; do
    echo "testing $cmd"
    [ "$cmd" = "ls" ] && continue
    run $APP $cmd
    [ $status -eq 1 ]
  done
}

@test "help exits with status code 10 when invalid arguments are passed to a command" {

  local skip_args=(
    install
    ls
    run
  )

  for cmd in ${APP_CMDS[@]} ; do
    echo "testing $cmd"
    run $APP $cmd --invalid-flag
    [ $status -eq 10 ]
    [[ "$output" == *"unrecognized flag"* ]]

    is/in_list "$cmd" "${skip_args[@]}" && continue

    run $APP $cmd invalid-argument
    echo "${lines[@]}"
    [ $status -eq 10 ]
    [[ "$output" == *"unrecognized argument"* ]]
  done
}
