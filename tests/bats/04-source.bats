#!/usr/bin/env bats

#
# 05 - runtime
#

load dex

setup(){
  [ -e $DEX ] || install_dex
}

@test "source ls displays sources.list matching our fixture" {
  diff <(cat_fixture source-ls.txt) <($DEX source ls)
}

@test "source add|ls|rm errors with 127 if missing sources.list" {
  # skipping -- currently unable to remove sources.list,
  #   as it's created by dex-init routine which fires before command execution
  skip
  for cmd in add ls rm; do
    run $DEX source $cmd junk junk
    [ $status -eq 127 ]
  done
}

@test "source add requires name and url, exits with code 2" {
  run $DEX source add
  [[ $output == *requires* ]]
  [ $status -eq 2 ]

  run $DEX source add abc
  [[ $output == *requires* ]]
  [ $status -eq 2 ]
}

@test "source add tests arg_var handling of flag arguments" {
  run $DEX source add aaa --a-flag-not-an-argument
  [ $status -eq 2 ]

  run $DEX source add -h
  [ $status -eq 0 ]
}

@test "source add supports local repository checkouts" {
  mk-repo
  run $DEX source add local $MK_REPO
  [ $status -eq 0 ]

  run $DEX source ls
  [ $status -eq 0 ]
  [ "${lines[2]}" = "local $MK_REPO" ]
}

@test "source add fails to add sources it cannot clone" {
  run $DEX source add unique fake-url.git
  [ $status -eq 1 ]
}

@test "source add refuses to duplicate existing names and urls" {
  run $DEX source ls
  [ $status -eq 0 ]

  IFS=" "
  read -r known_name known_url <<< "${lines[2]}"
  run $DEX source add $known_name fake-url.git

  [[ $output == *duplicate* ]]
  [ $status -eq 2 ]

  run $DEX source add unique $known_url
  [[ $output == *refusing* ]]
  [ $status -eq 2 ]

}

@test "source add refuses to add sources if a named checkout already exists" {
  mkdir $DEX_HOME/checkouts/unique

  run $DEX source add unique fake-url.git
  [[ $output == *refusing* ]]
  [ $status -eq 2 ]
}


@test "source add --force overwrites existing names" {
  mk-repo

  run $DEX source --force add core $MK_REPO
  [ $status -eq 0 ]

  IFS=" "
  $DEX source ls | while read -r name url; do
    if [ $name = "core" ]; then
      [ $url = $MK_REPO ]
    fi

    # "core" should have replaced "local" as it uses same url
    [ $name != "local" ]
  done
}

@test "source pull requires <sourcestr|*>" {
  run $DEX source pull
  [[ $output == *requires* ]]
  [ $status -eq 2 ]
}


@test "source pull creates (clones) a new checkout" {
  mk-repo
  run $DEX source --force add pulltest $MK_REPO
  [ $status -eq 0 ]

  rm -rf $DEX_HOME/checkouts/pulltest

  run $DEX source pull pulltest
  echo "$output"
  [ $status -eq 0 ]
  [ -d $DEX_HOME/checkouts/pulltest ]
}

@test "source pull updates (fetch+merge) clean checkouts" {
  mk-repo
  (
    cd $MK_REPO
    echo "more content" >> file
    git add file && git commit -m "more content"
  )
  run $DEX source pull pulltest
  [ $status -eq 0 ]
  diff $MK_REPO/file $DEX_HOME/checkouts/pulltest/file
}

@test "source pull fails to pull into a dirty checkout" {
  (
    cd $DEX_HOME/checkouts/pulltest
    echo "even more content" >> file
  )

  run $DEX source pull pulltest
  [[ $output == *changes* ]]
  [ $status -eq 1 ]
}

@test "source pull --force pulls into a dirty checkout" {
  mk-repo
  (
    cd $DEX_HOME/checkouts/pulltest
    echo "even more content" >> file
  )

  run $DEX source --force pull pulltest
  [ $status -eq 0 ]
  diff $MK_REPO/file $DEX_HOME/checkouts/pulltest/file
}

@test "source pull supports a wildcard sourcestr" {
  export DEX_NETWORK=false
  run $DEX source pull "*"
  echo $output
  $DEX source ls
  [[ $output == *extra* ]]
  [[ $output == *pulltest* ]]
  echo $output
}


@test "source rm requires a <sourcestr|*>" {
  run $DEX source rm
  [[ $output == *requires* ]]
  [ $status -eq 2 ]
}


@test "source rm errors if it cannot find the passed <sourcestr|*>" {
  run $DEX source rm highly-unlikely
  [ $status -eq 1 ]
}


@test "source rm fails to remove sources with a dirty checkout" {

  mk-repo
  run $DEX source --force add rmtest $MK_REPO
  [ $status -eq 0 ]

  (
    cd $DEX_HOME/checkouts/rmtest
    echo "more content" >> file
  )

  run $DEX source rm rmtest
  [[ $output == *changes* ]]
  [ $status -eq 1 ]
}


@test "source rm errors with status code 126 if it encounters unwritable checkouts" {
  chmod 000 $DEX_HOME/checkouts/rmtest
  run $DEX source rm rmtest
  [ $status -eq 126 ]
}


@test "source rm removes entry from sources.list and its associated checkout" {
  (
    chmod 755 $DEX_HOME/checkouts/rmtest
    cd $DEX_HOME/checkouts/rmtest
    git reset --hard
  )

  run $DEX source rm rmtest
  [ $status -eq 0 ]
  [ ! -d "$DEX_HOME/checkouts/rmtest" ]

  run grep -q -e "^rmtest " $DEX_HOME/sources.list
  [ $status -eq 1 ]
}
