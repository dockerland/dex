#!/usr/bin/env bats

#
# 05 - runtime
#

load dex

setup(){
  [ -e $DEX ] || install_dex
}

mk-repo(){
  MK_REPO=$TMPDIR/local-repo
  [ -e $MK_REPO/.git ] && return 0
  git init $MK_REPO || return 1
  (
    cd $MK_REPO
    echo "content" > file
    git add file || exit 1
    git commit -m "initial commit" || exit 1
  )

  return $?
}

@test "remote ls displays sources.list matching our fixture" {
  diff <(cat_fixture remote-ls.txt) <($DEX remote ls)
}

@test "remote add|ls|rm errors with 127 if missing sources.list" {
  # skipping -- currently unable to remove sources.list,
  #   as it's created by dex-setup routine which fires before command execution
  skip
  for cmd in add ls rm; do
    run $DEX remote $cmd junk junk
    [ $status -eq 127 ]
  done
}

@test "remote add requires name and url, exits with code 2" {
  run $DEX remote add
  [[ $output == *requires* ]]
  [ $status -eq 2 ]

  run $DEX remote add abc
  [[ $output == *requires* ]]
  [ $status -eq 2 ]
}

@test "remote add tests arg_var handling of flag arguments" {
  run $DEX remote add aaa --a-flag-not-an-argument
  [ $status -eq 127 ]

  run $DEX remote add -h
  [ $status -eq 0 ]
}

@test "remote add supports local repository checkouts" {

  mk-repo
  run $DEX remote add local $MK_REPO
  [ $status -eq 0 ]

  run $DEX remote ls
  [ $status -eq 0 ]
  [ "${lines[2]}" = $(printf "local\t$MK_REPO") ]
}

@test "remote add fails to add sources it cannot clone" {
  run $DEX remote add unique fake-url.git
  [ $status -eq 1 ]
}

@test "remote add refuses to duplicate existing names and urls" {
  run $DEX remote ls
  [ $status -eq 0 ]

  IFS=$'\t'
  while read known_name known_url; do
    run $DEX remote add $known_name fake-url.git
    [[ $output == *refusing* ]]
    [ $status -eq 2 ]

    run $DEX remote add unique $known_url
    [[ $output == *refusing* ]]
    [ $status -eq 2 ]
  done <<< "${lines[0]}"
}

@test "remote add refuses to add sources if a named checkout already exists" {
  mkdir $DEX_HOME/checkouts/unique

  run $DEX remote add unique fake-url.git
  [[ $output == *refusing* ]]
  [ $status -eq 2 ]
}


@test "remote add --force overwrites existing names" {
  mk-repo

  run $DEX remote --force add core $MK_REPO
  [ $status -eq 0 ]

  run $DEX remote ls

  IFS=$'\t'
  while read name url; do
    if [ $name = "core" ]; then
      [ $url = $MK_REPO ]
    fi
  done <<< "${lines[@]}"

}

@test "remote add --force overwrites existing URLs" {

}

@test "remote add --force overwrites existing checkouts" {

}

@test "remote pull errors if it is passed an invalid <name|url>" {

}

@test "remote pull creates a new checkout if it is non-existant" {

}

@test "remote pull updates a checkout if it already exists" {

}

@test "remote pull exits with status code 126 if it encounters unwritable checkouts" {

}

@test "remote pull errors if it is unable to update a local checkout" {

}


@test "remote rm requires a <name|url>" {
  run $DEX remote rm
  [[ $output == *requires* ]]
  [ $status -eq 2 ]
}


@test "remote rm errors if it cannot find the passed <name|url>" {
  run $DEX remote rm highly-unlikely
  [ $status -eq 1 ]
}


@test "remote rm fails to remove sources with a dirty checkout" {
  (
    cd $DEX_HOME/checkouts/local
    echo "more content" >> file
  )

  run $DEX remote rm local
  [[ $output == *changes* ]]
  [ $status -eq 1 ]
}


@test "remote rm errors with status code 126 if it encounters unwritable checkouts" {
  chmod 000 $DEX_HOME/checkouts/local
  run $DEX remote rm local
  [ $status -eq 126 ]
}


@test "remote rm removes entry from sources.list and its associated checkout" {
  (
    chmod 755 $DEX_HOME/checkouts/local
    cd $DEX_HOME/checkouts/local
    git reset --hard
  )

  run $DEX remote rm local
  [ $status -eq 0 ]
  [ ! -d "$DEX_HOME/checkouts/local" ]

  run grep -q -e "^local " sources.list
  [ $status -eq 1 ]
}
