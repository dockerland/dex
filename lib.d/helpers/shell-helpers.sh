#
# shell-helpers version v2.0.0-pr build ae3d8b0
#   https://github.com/briceburg/shell-helpers
# Copyright 2016-present Brice Burgess, Licensed under the Apache License 2.0
#
# shell-helpers - unfurl your arguments
#   https://github.com/briceburg/shell-helpers


# args/normalize - normalize POSIX short and long flags for easier parsing
# usage: args/normalize_flags <fargs> [<flags>...]
#   <fargs>: string of short flags requiring an argument.
#   <flags>: flag string(s) to normalize, typically passed as "$@"
# examples:
#   normalize_flags "" "-abc"
#     => -a -b -c
#   normalize_flags "om" "-abcooutput.txt" "--def=jam" "-mz"
#     => -a -b -c -o output.txt --def jam -m z"
#   normalize_flags "om" "-abcooutput.txt" "--def=jam" "-mz" "--" "-abcx" "-my"
#     => -a -b -c -o output.txt --def jam -m z -- -abcx -my"
args/normalize(){
  local fargs="$1"
  local passthru=false
  local output=""
  shift
  for arg in $@; do
    if $passthru; then
      output+=" $arg"
    elif [ "--" = "$arg" ]; then
      passthru=true
      output+=" --"
    elif [ "--" = ${arg:0:2} ]; then
      output+=" ${arg%=*}"
      [[ "$arg" == *"="* ]] && output+=" ${arg#*=}"
    elif [ "-" = ${arg:0:1} ]; then
      local p=1
      while ((p++)); read -n1 flag; do
        [ -z "$flag" ] || output+=" -$flag"
        if [[ "$fargs" == *"$flag"* ]]; then
          output+=" ${arg:$p}"
          break
        fi
      done < <(echo -n "${arg:1}")
    else
      output+=" $arg"
    fi
  done
  printf "%s" "${output:1}"
}

# args/normalize_flags_first - like args/, but outputs flags first.
# usage: args/normalize_flags_first <fargs> [<flags>...]
#   <fargs>: string of short flags requiring an argument.
#   <flags>: flag string(s) to normalize, typically passed as "$@"
# examples:
#   normalize_flags_first "" "-abc command -xyz otro"
#     => -a -b -c -x -y -z command otro
#   normalize_flags_first "" "-abc command -xyz otro -- -def xyz"
#     => -a -b -c -x -y -z command otro -- -def xyz

args/normalize_flags_first(){
  local fargs="$1"
  local output=""
  local cmdstr=""
  local passthru=false
  shift
  for arg in $(args/normalize "$fargs" "$@"); do
    [ "--" = "$arg" ] && passthru=true
    if $passthru || [ ! "-" = ${arg:0:1} ]; then
      cmdstr+=" $arg"
      continue
    fi
    output+=" $arg"
  done
  printf "%s%s" "${output:1}" "$cmdstr"
}

args/unknown(){
  io/shout "\e[1m$1\e[21m is an unrecognized ${2:-argument}"
  display_help 2
}
# shell-helpers - the art of killing your script
#   https://github.com/briceburg/shell-helpers

die(){
  io/error "${@:-halting...}"
  exit ${__exit_code:-1}
}

die/noent(){
  __exit_code=127
  die "$@"
}

die/perms(){
  __exit_code=126
  die "$@"
}

die/exception() {
  __exit_code=2
  die "$@"
}
# shell-helpers - docker the things
#   https://github.com/briceburg/shell-helpers

docker/deactivate_machine(){
  # @TODO support boot2docker / concept of "default" machine
  is/cmd docker-machine && {
    eval $(docker-machine env --unset --shell bash)
    return
  }
  # lets be safe and unset if missing docker-machine
  unset DOCKER_HOST DOCKER_TLS_VERIFY DOCKER_CERT_PATH DOCKER_MACHINE_NAME
}

# docker/local - run docker against the local engine
docker/local()(
  docker/deactivate_machine
  exec docker "$@"
)

# docker/local-compose - run docker-compose against the local engine
docker/local-compose()(
  docker/deactivate_machine
  exec docker-compose "$@"
)

# docker/safe_name - sanitize a string for use as a container or image name
docker/safe_name(){
  local name="$@"
  set -- "${name:0:1}" "${name:1}"
  printf "%s%s" "${1//[^a-zA-Z0-9]/0}" "${2//[^a-zA-Z0-9_.-]/_}"
}



# print Dockerfiles found in a path. filter by tag and/or extension.
#  follows symlinks to resolve extension validity. legal default examples;
#    /path/Dockerfile
#    /path/Dockerfile-1.2.0
#    /path/Dockerfile-1.3.0.j2
find/dockerfiles(){
  local path="${1:-.}" ; shift
  local filter_tag="$1" ; shift
  local filter_extensions=( "${@:-j2 Dockerfile}" )

  (
    found=false
    cd $path 2>/dev/null

    for Dockerfile in Dockerfile* ; do
      [ -e "$Dockerfile" ] || continue

      filename="$Dockerfile"
      tag="$(find/dockerfile-tag $Dockerfile)"

      # skip tags not matching our filter
      [[ -n "$filter_tag" && "$tag" != "$filter_tag" ]] && continue

      # resolve extension
      extension="${filename##*.}"
      while [ -L "$path/$filename" ]; do
        filename=$(readlink $path/$filename)
        extension=${filename##*.}
      done

      # skip files not matching our extension filter
      [ -n "$extension" ] && is/in_list "$extension" "${filter_extensions[@]}" && continue

      echo "$path/$Dockerfile"
      found=true
    done

    $found
  )

}

# print the tag of a passed Dockerfile path
#  /path/to/Dockerfile => latest
#  Dockerfile-1.2.0 => 1.2.0
find/dockerfile-tag(){
  local Dockerfile="$(basename $1)"
  local filename=${Dockerfile%.*}
  local tag=${filename//Dockerfile-/}
  tag=${tag//Dockerfile/latest}
  echo "$tag"
}
# shell-helpers - file/fs manipulation
#   https://github.com/briceburg/shell-helpers


# file/sed_inplace - cross-platform sed "in place" file substitution
# usage: sed_inplace "file" "sed regex pattern"
#    ex: sed_inplace "/tmp/file" "s/CLIENT_CODE/ACME/g"
#    ex: sed_inplace "/tmp/file" "/pattern_to_remove/d"
file/sed_inplace(){
  local sed=
  local sed_flags="-r -i"

  for sed in gsed /usr/local/bin/sed sed; do
    type $sed &>/dev/null && break
  done

  [ "$sed" = "sed" ] && [[ "$OSTYPE" =~ darwin|macos* ]] && sed_flags="-i '' -E"
  $sed $sed_flags "$2" $1
}

# file/interpolate - interpolates a match in a file, or appends if no match
#                    similar to ansible line_in_file
# usage: file/interpolate <file> <match> <content>
#    ex: file/interpolate  "default.vars" "^VARNAME=.*$" "VARNAME=value"
file/interpolate(){
  local delim=${4:-"|"}
  if is/in_file "$1" "$2"; then
    file/sed_inplace "$1" "s$delim$2$delim$3$delim"
  else
    echo "$3" >> "$1"
  fi
}
# shell-helpers - look up. climb tree. look down. look around.
#   https://github.com/briceburg/shell-helpers

# find/cmd - return first usable command, preferring __cmd_prefix versions
# usage: find/cmd <command(s)...>
# example:
#  ansible=$(__cmd_prefix=badevops- find/cmd ansible dansible) =>
#   1. "badevops-ansible"
#   2. "badevops-dansible"
#   3. "ansible"
#   4. "dansible"
#   5. "" - returns 127
find/cmd(){
  local cmd=
  for cmd in "$@"; do
    type ${__cmd_prefix}${cmd} &>/dev/null && {
      echo "${__cmd_prefix}${cmd}"
      return 0
    }
  done

  for cmd in "$@"; do
    type $cmd &>/dev/null && {
      echo "$cmd"
      return 0
    }
  done

  return 127
}

# usage: find/dirs <path> [filter]
find/dirs(){
  local path="$1"
  local filter="$2"
  [ -z "$filter" ] && filter="*"
  [ -d "$path" ] || die "$FUNCNAME - invalid path: $path"
  (
    cd "$path"
    ls -1d $filter/ 2>/dev/null | sed 's|/$||'
  )
}


# usage: find/gid_from_name <group name>
find/gid_from_name(){
  if is/cmd getent ; then
    getent group "$1" | cut -d: -f3
  elif is/cmd dscl ; then
    dscl . -read "/Groups/$1" PrimaryGroupID 2>/dev/null | awk '{ print $2 }'
  else
    python -c "import grp; print(grp.getgrnam(\"$1\").gr_gid)" 2>/dev/null
  fi
}

# usage: find/gid_from_file <path>
find/gid_from_path(){
  ls -ldn "$1" 2>/dev/null | awk '{print $4}'
}
# shell-helpers - git thingers
#   https://github.com/briceburg/shell-helpers


# usage: git/clone <repo-path-or-url> <destination>
git/clone(){
  local url="$1"
  local target="$2"
  prompt/overwrite "$target" || return 1

  [ -w $(dirname $target) ] || {
    io/warn "$target parent directory not writable"
    return 126
  }

  local flags=""
  if ! is/url "$url"; then
    [ -d "$url/.git" ] || {
      io/warn "$url is not a git repository"
      return 2
    }
    flags+=" --shared"
  fi

  git clone $flags "$url" "$target"
}


# usage: git/pull <repo path>
git/pull(){
  local path="${1:-.}"
  (
    cd "$path"
    if is/dirty && ! $__force ; then
      prompt/confirm "overwrite working copy changes in $path ?" || return 1
    fi
    git reset --hard HEAD
    git pull
  )
}

# is/dirty [path to git repository]
is/dirty(){
  local path="${1:-.}"
  [ -d "$path/.git" ] || {
    io/warn "$path is not a git repository."
    return 0
  }

  (
    set -e
    cd "$path"
    [ -n "$(git status -uno --porcelain)" ]
  )
}
# shell-helpers - you put your left foot in, your right foot out.
#   https://github.com/briceburg/shell-helpers

#
# printf outputs
#

io/error(){
  io/blockquote "\e[31m" "✖ " "$@" >&2
}

io/success(){
  io/blockquote "\e[32m" "✔ " "$@" >&2
}

io/notice(){
  io/blockquote "\e[33m" "➜ " "$@" >&2
}

io/log(){
  io/blockquote "\e[34m" "• " "$@" >&2
}

io/warn(){
  io/blockquote "\e[35m" "⚡ " "$@" >&2
}

io/comment(){
  printf '\e[90m# %b\n\e[0m' "$@" >&2
}

io/shout(){
  printf '\e[33m⚡\n⚡ %b\n⚡\n\e[0m' "$@" >&2
}

io/header(){
  printf "========== \e[1m$1\e[21m ==========\n"
}

io/blockquote(){
  local escape="$1" ; shift
  local prefix="$1" ; shift
  local indent="$(printf '%*s' ${#prefix})"

  while [ $# -ne 0 ]; do
    printf "$escape$prefix%b\n\e[0m" "$1"
    prefix="$indent"
    shift
  done
}
# shell-helpers - you put your left foot in, your right foot out.
#   https://github.com/briceburg/shell-helpers

is/absolute(){
  [[ "${1:0:1}" == / || "${1:0:2}" == ~[/a-z] ]]
}

is/cmd(){
  type "$1" &>/dev/null
}

# is/url <string> - returns true on [protocol]://... or user@host:...
is/url(){
  [[ "$1" == *"://"* ]] || [[ "$1" == *"@"* && "$1" == *":"* ]]
}

is/fn(){
  [ "$(type -t $1)" = "function" ]
}

# is/in_file <file> <pattern to match>
is/in_file(){
  grep -q "$1" "$2" 2>/dev/null
}

is/in_list(){
  local match="$1" ; shift
  local item
  for item in "$@"; do
    [ "$item" = "$match" ] && return 0
  done
  return 1
}
# shell-helpers - a series of tubes and pipes provided by al gore
#   https://github.com/briceburg/shell-helpers

# usage: network/fetch <url> <target>
network/fetch(){
  local url="$1"
  local target="$2"
  prompt/overwrite "$target" || return 1
  network/print "$url" > "$target"
}

# usage: network/print <url>
# similar to network/fetch but prints a URL to stdout
network/print(){
  local url="$1"
  local wget=${WGET_PATH:-wget}
  local curl=${CURL_PATH:-curl}

  is/url "$url" || {
    io/warn "refusing to fetch $url"
    return 1
  }

  if is/cmd $wget ; then
    $wget -qO - $url
  elif is/cmd $curl ; then
    $curl -Lfs $url
  else
    io/warn "unable to fetch $url" "missing both curl and wget"
    return 1
  fi
}

# shell_detect - detect user's shell and sets
#  __shell (user's shell, e.g. 'fish', 'bash', 'zsh')
#  __shell_file (shell configuration file, e.g. '~/.bashrc')
# usage: shell_detect [shell (skips autodetect)]
shell/detect(){
  # https://github.com/rbenv/rbenv/wiki/Unix-shell-initialization
  __shell=${1:-$(basename $SHELL | awk '{print tolower($0)}')}
  __shell_file=

  local search
  local path
  case $__shell in
    bash|sh   ) search=".bashrc .bash_profile" ;;
    cmd       ) search=".profile" ;;
    ash|dash  ) search=".profile" ;;
    fish      ) search=".config/fish/config.fish" ;;
    ksh       ) search=".kshrc" ;;
    powershell) search=".profile" ;;
    tcsh      ) search=".tcshrc .cshrc .login" ;;
    zsh       ) search=".zshenv .zprofile .zshrc" ;;
    *         ) die/exception "unrecognized shell \"$__shell\"" ;;
  esac

  for path in $search; do
    [ -e ~/$path ] && {
      __shell_file=~/$path
      return 0
    }
  done

  __shell_file=~/.profile
  io/warn "failed detecting shell config file, falling back to $__shell_file"
  return 1
}

# shell/evaluable_export - print evaluable commands to export a variable
#   requires __shell to be set (via shell/detect)
# usage: shell/evaluable_export <variable> <value> [append_flag] [append_delim]
shell/evaluable_export(){
  local append=${3:-false}
  local append_delim="$4"
  [[ "$1" = "PATH" && -z "$append_delim" ]] && append_delim=':'

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
}

shell/evaluable_entrypoint(){
  local pre
  local post

  case $__shell in
    cmd       ) pre="@FOR /f "tokens=*" %i IN ('" post="') DO @%i'" ;;
    fish      ) pre="eval (" post=")" ;;
    tcsh      ) pre="eval \`" post="\`" ;;
    powershell) pre="&" post=" | Invoke-Expression" ;;
    *         ) pre="eval \$(" ; post=")" ;;
  esac

  [ -z "$__shell_file" ] && shell/detect

  io/comment \
    "To configure your shell, run:" \
    "  ${pre}${SCRIPT_ENTRYPOINT}${post}" \
    "To remember your configuration in subsequent shells, run:" \
    "  echo ${pre}${SCRIPT_ENTRYPOINT}${post} >> $__shell_file"
}


# shell/execfn <function name> [args...]
shell/execfn(){
  is/fn "$1" || die/exception "$1 is not a target function"

  "$@"
  exit $?
}
# prompt - prompt for input, useful for assigning variiable values
# usage: prompt <prompt message> [fallback value*]
#   * uses fallback value if no input recieved or a tty is not available
# example:
#   name=$(prompt  "name to encrypt")
#   port=$(prompt  "port" 8080)
prompt(){
  local input=
  local prompt="${1:-value}"
  local default="$2"
  [ -z "$default" ] || prompt+=" [$default]"

  # convert escape sequences in prompt to ansi codes
  prompt="$(echo -e -n "$prompt : ")"

  while [ -z "$input" ]; do
    if [ -t 0 ]; then
      # user input
      read -p "$prompt" input </dev/tty
    else
      # piped input
      read input
    fi

    [[ -n "$default" && -z "$input" ]] && input="$default"
    [ -z "$input" ] && io/warn "invalid input"

  done
  echo "$input"
}

# prompt/confirm - pause before continuing
# usage: prompt/confirm [message]
# examples:
#  prompt/confirm "really?" || exit 0
prompt/confirm() {
  while true; do
    case $(prompt "${@:-Continue?} [y/n]") in
      [yY]) return 0 ;;
      [nN]) return 1 ;;
      *) io/warn "invalid input"
    esac
  done
}

# prompt/overwrite - prompt before removing a path
prompt/overwrite(){
  local target="$1"
  local prompt="${2:-overwrite $target ?}"
  local force=${__force:-false}
  [ ! -e "$target" ] || {
    $force || prompt/confirm "$prompt" || return 1
    rm -rf "$target"
  }
}
# @shell-helpers_UPDATE_URL=http://get.iceburg.net/shell-helpers/latest-v2/shell-helpers.sh
