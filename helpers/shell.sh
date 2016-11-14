
# shell_detect - detect user's shell and sets
#  __shell (user's shell, e.g. 'fish', 'bash', 'zsh')
#  __shell_file (shell configuration file, e.g. '~/.bashrc')
# usage: shell_detect [shell (skips autodetect)]
shell_detect(){
  # https://github.com/rbenv/rbenv/wiki/Unix-shell-initialization
  __shell=${1:-$(basename $SHELL | awk '{print tolower($0)}')}
  __shell_file=

  local search=
  case $__shell in
    bash|sh   ) search=".bashrc .bash_profile" ;;
    cmd       ) search=".profile" ;;
    ash|dash  ) search=".profile" ;;
    fish      ) search=".config/fish/config.fish" ;;
    ksh       ) search=".kshrc" ;;
    powershell) search=".profile" ;;
    tcsh      ) search=".tcshrc .cshrc .login" ;;
    zsh       ) search=".zshenv .zprofile .zshrc" ;;
    *         ) error_exception "unrecognized shell \"$__shell\"" ;;
  esac

  for file in $search; do
    [ -e ~/$file ] && {
      __shell_file=~/$file
      return 0
    }
  done

  __shell_file=~/.profile
  echo "# failed to detect shell config file, falling back to $__shell_file"
  return 1
}

# shell_eval_export - print evaluable commands to export a variable
# usage: shell_eval_export <variable> <value> [append_flag] [append_delim]
shell_eval_export(){
  local append=${3:-false}
  local append_delim=$4
  [ "$1" = "PATH" ] && [ -z "$append_delim" ] && append_delim=':'

  if $append; then
    case $__shell in
      cmd       ) echo "SET $1=%${1}%${append_delim}${2}" ;;
      fish      ) echo "set -gx $1 \$${1} ${2};" ;;
      tcsh      ) echo "setenv $1 = \$${1}${append_delim}${2}" ;;
      powershell) echo "\$Env:$1 = \"\$${1}${append_delim}${2}\";" ;;
      *         ) echo "export $1=\"\$${1}${append_delim}${2}\"" ;;
    esac
  else
    case $__shell in
      cmd       ) echo "SET $1=$2" ;;
      fish      ) echo "set -gx $1 \"$2\";" ;;
      tcsh      ) echo "setenv $1 \"$2\"" ;;
      powershell) echo "\$Env:$1 = \"$2\";" ;;
      *         ) echo "export $1=\"$2\"" ;;
    esac
  fi

  shell_eval_message
}

shell_eval_message(){
  #@TODO transform entrypoint to absolute path

  local pre
  local post

  case $__shell in
    cmd       ) pre="@FOR /f "tokens=*" %i IN ('" post="') DO @%i'" ;;
    fish      ) pre="eval (" post=")" ;;
    tcsh      ) pre="eval \`" post="\`" ;;
    powershell) pre="&" post=" | Invoke-Expression" ;;
    *         ) pre="eval \$(" ; post=")" ;;
  esac

  echo "# To configure your shell, run:"
  echo "#   ${pre}${__entrypoint}${post}"
  echo "# To remember your configuration in subsequent shells, run:"
  echo "#   echo ${pre}${__entrypoint}${post} >> $__shell_file"
}
