#!/usr/bin/env bats

#
# 30 - initialization and configuration
#

load app

@test "repo ls prints available repositories, matches sources.list fixture" {
  diff <(fixture/cat sources.list | io/no-comments) <($APP repo ls)
}

@test "repo ls supports filtering by repository names" {
  [ $($APP repo ls | wc -l) -gt  $($APP repo ls core extra | wc -l) ]
  [ $($APP repo ls core extra | wc -l) -eq 2 ]
}

@test "repo ls supports wildcard filtering" {
  [ $($APP repo ls -- "c*" | wc -l) -eq 1 ]
  [ $($APP repo ls -- "*xtr*" | wc -l) -eq 1 ]
}

@test "repo ls supports dex/repo-exists by returning empty if no repo matches" {
  [ -z "$($APP repo ls -- nonexistant)" ]
  $APP runfunc dex/repo-exists core
  ! $APP runfunc dex/repo-exists non-existant
}

@test "repo add requires name _and_ url, errexits" {
  run $APP repo add name
  [ $status -gt 0 ]
  [[ "$output" == *"please provide a repo name and url"* ]]
}

@test "repo add refuses to add repositories it cannot checkout" {
  mkdir "$TMPDIR/test-non-repo"
  run $APP repo add test-repo "$TMPDIR/test-non-repo"
  [ $status -eq 2 ]

  $SKIP_NETWORK_TEST || {
    DEX_NETWORK=true run $APP repo add test-repo git@github.com:briceburg/repository-maybe-hopefully-not-ever-exists.git
    [ $status -eq 2 ]
  }

  [ -z "$($APP repo ls test-repo)" ]
}

@test "repo add checks out source repositories" {
  make/repo "$TMPDIR/test-repo"
  run $APP repo add test-repo "$TMPDIR/test-repo"
  [ $status -eq 0 ]
  [ -n "$($APP repo ls test-repo)" ]

  app/var __checkouts
  [ $(git --git-dir "$TMPDIR/test-repo"/.git rev-parse HEAD) = "$(git --git-dir $__checkouts/test-repo/.git rev-parse HEAD)" ]
}

@test "repo add prompts before overwriting existing checkouts" {
  make/repo "$TMPDIR/test-repo"
  app/var __checkouts
  mkdir -p "$__checkouts/test-overwrite/blah"
  yes "n" | $APP repo add test-overwrite "$TMPDIR/test-repo" || true
  [ -z "$($APP repo ls test-overwrite)" ]

  yes "y" | $APP repo add test-overwrite "$TMPDIR/test-repo" || true
  [ -n "$($APP repo ls test-overwrite)" ]
}

@test "repo add respects --force flag, disables prompting" {
  make/repo "$TMPDIR/test-repo"
  run $APP repo add --force test-repo "$TMPDIR/test-repo"
  [ $status -eq 0 ]
  [ -n "$($APP repo ls test-repo)" ]
}

@test "repo pull refreshes available repositories" {
  DEX_NETWORK=false run $APP repo pull
  [[ "$output" == *"pulling core"* ]]
  [[ "$output" == *"pulling extra"* ]]
  [[ "$output" == *"pulling find-test"* ]]
}

@test "repo pull allows specifiying repositories to pull" {
  DEX_NETWORK=false run $APP repo pull find-test extra
  [[ "$output" != *"pulling core"* ]]
  [[ "$output" == *"pulling extra"* ]]
  [[ "$output" == *"pulling find-test"* ]]
}

@test "repo pull refreshes checkouts from source repository" {
  make/repo "$TMPDIR/test-repo"
  $APP repo add --force test-repo "$TMPDIR/test-repo"
  [ -n "$($APP repo ls test-repo)" ]

  # add a commit to source repo
  (
    set -e
    cd "$TMPDIR/test-repo"
    echo "blah" >> file
    git add file
    git commit -m "additional commit"
  )

  app/var "__checkouts"

  # ensure we're on different commits
  [ $(git --git-dir "$TMPDIR/test-repo/.git" rev-parse HEAD) != "$(git --git-dir "$__checkouts/test-repo/.git" rev-parse HEAD)" ]

  $APP repo pull test-repo
  # ensure we're at the same commit
  [ $(git --git-dir "$TMPDIR/test-repo/.git" rev-parse HEAD) = "$(git --git-dir "$__checkouts/test-repo/.git" rev-parse HEAD)" ]
}

@test "repo pull prompts before refreshing dirty checkouts" {
  make/repo "$TMPDIR/test-repo"
  $APP repo add --force test-repo "$TMPDIR/test-repo"
  [ -n "$($APP repo ls test-repo)" ]

  app/var "__checkouts"
  echo "dirty-test" >> "$__checkouts/test-repo/file"

  yes "n" | $APP repo pull test-repo || true
  is/in_file "dirty-test" "$__checkouts/test-repo/file"

  yes "y" | $APP repo pull test-repo
  ! is/in_file "dirty-test" "$__checkouts/test-repo/file"
}

@test "repo pull respects --force flag" {
  make/repo "$TMPDIR/test-repo"
  $APP repo add --force test-repo "$TMPDIR/test-repo"
  [ -n "$($APP repo ls test-repo)" ]

  app/var "__checkouts"
  echo "dirty-test" >> "$__checkouts/test-repo/file"

  $APP repo pull --force test-repo
  ! is/in_file "dirty-test" "$__checkouts/test-repo/file"
}

@test "repo rm prompts before removing a repository" {
  make/repo "$TMPDIR/test-repo"
  $APP repo add --force test-repo "$TMPDIR/test-repo"
  [ -n "$($APP repo ls test-repo)" ]

  yes "n" | run $APP repo rm test-repo || true
  [ -n "$($APP repo ls test-repo)" ]
  [ -n "$($APP repo ls core)" ]

  yes "y" | run $APP repo rm test-repo
  [ -z "$($APP repo ls test-repo)" ]
  [ -n "$($APP repo ls core)" ]
}

@test "repo reset downloads source.list, falls back to built-in defaults" {
  make/repo "$TMPDIR/test-repo"
  $APP repo add --force test-repo "$TMPDIR/test-repo"
  [ -n "$($APP repo ls test-repo)" ]

  app/var SCRIPT_BUILD
  DEX_NETWORK=false run $APP repo reset
  echo "${lines[@]}"
  [ $status -eq 0 ]
  [[ "$output" == *"refusing to fetch"* ]]
  [[ "$output" == *"loading build $SCRIPT_BUILD defaults"* ]]
  [ -z "$($APP repo ls test-repo)" ]
}
