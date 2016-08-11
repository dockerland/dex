#!/usr/bin/env bats

#
# 05 - runtime
#

load dex

setup(){
  [ -e $DEX ] || install_dex
}

@test "remote ls displays sources.list matching our fixture" {
  diff <(cat_fixture remote-ls.txt) <($DEX remote ls)
}

@test "remote add|ls|rm errors with 127 if missing sources.list" {
  # skipping -- currently unable to remove sources.list,
  #   as it's created by dex-init routine which fires before command execution
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

@test "remote pull requires a <name|url>" {
  run $DEX remote pull
  [[ $output == *requires* ]]
  [ $status -eq 2 ]
}


@test "remote pull creates a new checkout if it is non-existant" {
  mk-repo
  run $DEX remote --force add pulltest $MK_REPO
  [ $status -eq 0 ]

  rm -rf $DEX_HOME/checkouts/pulltest

  run $DEX remote pull pulltest
  [ $status -eq 0 ]
  [ -d $DEX_HOME/checkouts/pulltest ]
}

@test "remote pull pulls updates into a clean checkout" {
  mk-repo
  (
    cd $MK_REPO
    echo "more content" >> file
    git add file && git commit -m "more content"
  )
  run $DEX remote pull pulltest
  [ $status -eq 0 ]
  diff $MK_REPO/file $DEX_HOME/checkouts/pulltest/file
}

@test "remote pull fails to pull into a dirty checkout" {
  (
    cd $DEX_HOME/checkouts/pulltest
    echo "even more content" >> file
  )

  run $DEX remote pull pulltest
  [[ $output == *changes* ]]
  [ $status -eq 1 ]
}

@test "remote pull --force pulls into a dirty checkout" {
  mk-repo
  (
    cd $DEX_HOME/checkouts/pulltest
    echo "even more content" >> file
  )

  run $DEX remote --force pull pulltest
  [ $status -eq 0 ]
  diff $MK_REPO/file $DEX_HOME/checkouts/pulltest/file
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

  mk-repo
  run $DEX remote --force add rmtest $MK_REPO
  [ $status -eq 0 ]

  (
    cd $DEX_HOME/checkouts/rmtest
    echo "more content" >> file
  )

  run $DEX remote rm rmtest
  [[ $output == *changes* ]]
  [ $status -eq 1 ]
}


@test "remote rm errors with status code 126 if it encounters unwritable checkouts" {
  chmod 000 $DEX_HOME/checkouts/rmtest
  run $DEX remote rm rmtest
  [ $status -eq 126 ]
}


@test "remote rm removes entry from sources.list and its associated checkout" {
  (
    chmod 755 $DEX_HOME/checkouts/rmtest
    cd $DEX_HOME/checkouts/rmtest
    git reset --hard
  )

  run $DEX remote rm rmtest
  [ $status -eq 0 ]
  [ ! -d "$DEX_HOME/checkouts/rmtest" ]

  run grep -q -e "^rmtest " sources.list
  [ $status -eq 1 ]
}
