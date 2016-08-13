#
# lib.d/helpers/argparse.sh for dex -*- shell-script -*-
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

unrecognized_arg(){

  if [ $__cmd = "main" ]; then
    printf "\n\n$1 is an unrecognized command\n\n"
  else
    printf "\n\n$1 is an unrecognized argument to the $__cmd command.\n\n"
  fi

  display_help 127
}
