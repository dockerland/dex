#
# lib.d/helpers/cli.sh for dex -*- shell-script -*-
#

# normalize_flags - normalize POSIX short and long flags for easier parsing 
# usage: normalize_flags <fargs> [<flags>...]
#   <fargs>: string of short flags requiring an argument.
#   <flags>: flag string(s) to normalize, typically passed as "$@"
# examples:
#   normalize_flags "" "-abc"
#     => -a -b -c
#   normalize_flags "om" "-abcooutput.txt" "--def=jam" "-mz" 
#     => -a -b -c -o output.txt --def jam -m z"
normalize_flags(){
  local fargs="$1"
  shift
  while [ $# -ne 0 ]; do
    if [ "--" = ${1:0:2} ]; then
      echo ${1%=*}
      [[ "$1" == *"="* ]] && echo ${1#*=}
    elif [ "-" = ${1:0:1} ]; then
      local i=1
      while read -n1 flag; do
        ((i++))
        [ -z "$flag" ] || echo "-$flag"
        if [[ "$fargs" == *"$flag"* ]]; then
          echo ${1:$i}
          break
        fi
      done < <(echo -n "${1:1}")
    else
      echo $1
    fi
    shift
  done
}

unrecognized_flag(){
  if [ $__cmd = "main" ]; then
    printf "\n\n$1 is an unrecognized flag\n\n"
  else
    printf "\n\n$1 is unrecognized by the $__cmd command.\n\n"
  fi

  display_help 2
}

unrecognized_arg(){

  if [ $__cmd = "main" ]; then
    printf "\n\n$1 is an unrecognized command\n\n"
  else
    printf "\n\n$1 is an unrecognized argument to the $__cmd command.\n\n"
  fi

  display_help 2
}

#
# @TODO deprecate below
#

# usage:  arg_var <arg> <variiable>
# assigns a variable from an argument if <arg> is not a flag, else clears it
arg_var(){
  if [[  $1 == -* ]]; then
    eval "$2="
    return 1
  else
    eval "$2=\"$1\""
    return 0
  fi
}
