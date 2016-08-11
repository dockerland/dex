#!/usr/bin/env bash

CWD=$(dirname $0)
lint_paths=( bats )
filter=""

for path in $lint_paths; do
  printf "\n* testing scripts in $path ...\n"
  for script in $(find $CWD/$path/ -type f $filter); do
    printf "\n* testing $script ...\n"
    bash -n $script || printf "\n\n* ERROR in $script\n\n"
  done
done
