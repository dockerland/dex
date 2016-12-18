#
# shell-helpers version v2.0.0-pr build f2f87c2
#   https://github.com/briceburg/shell-helpers
# Copyright 2016-present Brice Burgess, Licensed under the Apache License 2.0
#
# shell-helpers - unfurl your arguments
#   https://github.com/briceburg/shell-helpers


# args/normalize - normalize POSIX short and long flags for easier parsing
# usage: args/normalize <fargs> [<flags>...]
#   <fargs>: string of short flags requiring an argument.
#   <flags>: flag string(s) to normalize, typically passed as "$@"
# examples:
#   args/normalize "" "-abc"
#     => -a -b -c
#   args/normalize "om" "-abcooutput.txt" "--def=jam" "-mz"
#     => -a -b -c -o output.txt --def jam -m z"
#   args/normalize "om" "-abcooutput.txt" "--def=jam" "-mz" "--" "-abcx" "-my"
#     => -a -b -c -o output.txt --def jam -m z -- -abcx -my"
args/normalize(){
  local fargs="$1" ; shift || true
  local passthru=false
  local output=""
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
  local fargs="$1" ; shift || true
  local output=""
  local cmdstr=""
  local passthru=false
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
  p/shout "\e[1m$1\e[21m is an unrecognized ${2:-argument}"
  die/help 10
}
# shell-helpers - the art of killing your script
#   https://github.com/briceburg/shell-helpers

die(){
  p/error "${@:-halting...}"
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

# die/help <exit code> <message text...>
#  calls p/help_[cmd] function. (e.g. calls p/help_main from main() fn)
#  help messages are prefixed w/ any message text, such as warnings about
#  about missing arguments.
die/help(){
  local status="$1" ; shift || true

  # functions starting with main_ indicate command name.
  # attempt to auto-detect by examining call stack
  local fn
  for fn in "${FUNCNAME[@]}"; do
    [ "main" = "${fn:0:4}" ] && {
      cmd="${fn//main_/}"
      is/fn "p/help_$cmd" || continue
      [ -z "$@" ] || p/shout "$@"
      p/help_$cmd
      exit $status
    }
  done

  die/exception "failed to detect helpfile from function stack" "${FUNCNAME[@]}"
}

# example p/help_<cmd> function
# p/help_cmd(){
#   cat <<-EOF
#
# util - because you need util
#
# Usage:
#   util cmd [options...] <command>
#
# Options:
#   -h|--help
#     Displays help
#
#   -d|--defaults
#     Temporarily resets the current environment and prints default values
#
# Commands:
#   vars [-d|--defaults] [--] [list...]
#     Prints configuration variables as evaluable output
#
# EOF
# }
# shell-helpers - docker the things
#   https://github.com/briceburg/shell-helpers

docker/deactivate-machine(){
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
  docker/deactivate-machine
  exec docker "$@"
)

# docker/local-compose - run docker-compose against the local engine
docker/local-compose()(
  docker/deactivate-machine
  exec docker-compose "$@"
)


# print Dockerfiles found in a path. filter by tag and/or extension.
#  follows symlinks to resolve extension validity. legal default examples;
#    /path/Dockerfile
#    /path/Dockerfile-1.2.0
#    /path/Dockerfile-1.3.0.j2
docker/find/dockerfiles(){
  local path="${1:-.}" ; shift || true
  local filter_tag="$1" ; shift || true
  local filter_extensions=( "${@:-j2 Dockerfile}" )

  (
    found=false
    cd "$path" 2>/dev/null || exit 1

    for Dockerfile in Dockerfile* ; do
      [ -e "$Dockerfile" ] || continue

      filename="$Dockerfile"
      tag="$(docker/get/dockerfile-tag $Dockerfile)"

      # skip tags not matching our filter
      [[ -n "$filter_tag" && "$tag" != "$filter_tag" ]] && continue

      # resolve extension
      extension="${filename##*.}"
      while [ -L "$path/$filename" ]; do
        filename=$(readlink "$path/$filename")
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

# docker/find/labels <name|sha> [type (container|image)]
#  outputs labels one per line as "<label name> <label value>"
docker/find/labels(){
  local lookup="$1"
  local type="$2"
  local format="${__format:-\$label \$value\n}"

  [ -n "$type" ] && type="--type $type"
  local label
  local value

  docker/local inspect $type -f '{{range $key, $value := .Config.Labels }}{{println $key $value }}{{ end }}' $lookup |
  while read label value ; do
    [ -z "$label" ] && continue
    eval "printf \"$format\""
  done
}

# docker/find/repotags <name|sha> [type (container|image)]
#  outputs names (repository tags) one per line
docker/find/repotags(){
  local lookup="$1"
  local type="$2"

  [ -n "$type" ] && type="--type $type"
  local name

  docker/local inspect $type -f '{{range $name := .RepoTags }}{{println $name }}{{ end }}' $lookup |
  while read name ; do
    [ -z "$name" ] && continue
    echo "$name"
  done
}


# print the tag of a passed Dockerfile path - this is used by buildchain,
# and related to docker/find/dockerfiles
#  /path/to/Dockerfile => latest
#  Dockerfile-1.2.0 => 1.2.0
docker/get/dockerfile-tag(){
  local Dockerfile="$(basename $1)"
  local filename=${Dockerfile%.*}
  local tag=${filename//Dockerfile-/}
  tag=${tag//Dockerfile/latest}
  echo "$tag"
}

# docker/get/name <name|sha> [type (container|image)]
docker/get/repotag(){
  docker/find/repotags "$@" | head -n1
}

# docker/get/id <name|repotag> [type (container|image)]
docker/get/id(){
  local lookup="$1"
  local type="$2"

  [ -n "$type" ] && type="--type $type"
  docker/local inspect $type -f '{{ .Id }}' $lookup
}


# docker/get/safe-name <strings> [append list...]
#   sanitize strings into a safe container or image name
docker/get/safe-name(){
  local name="$@"
  set -- "${name:0:1}" "${name:1}"
  printf "%s%s" "${1//[^a-zA-Z0-9]/0}" "${2//[^a-zA-Z0-9_.-]/_}"
}
# shell-helpers - file/fs manipulation
#   https://github.com/briceburg/shell-helpers


# file/sed_inplace - cross-platform sed "in place"
# usage: file/sed_inplace "sed script" "file"
#    ex: file/sed_inplace "s/CLIENT_CODE/ACME/g" "/tmp/file"
#    ex: file/sed_inplace "/pattern_to_remove/d" "/tmp/file"
file/sed_inplace(){
  local script="$1"
  local file="$2"
  local sed_flags="-r -i"
  local sed

  for sed in gsed /usr/local/bin/sed sed; do
    type $sed &>/dev/null && break
  done

  [ "$sed" = "sed" ] && [[ "$OSTYPE" =~ darwin|macos* ]] && sed_flags="-i '' -E"
  $sed $sed_flags "$script" "$file"
}

# file/interpolate - interpolates a match in a file, or appends if no match
#                    similar to ansible line_in_file
# usage: file/interpolate <pattern> <replace> <file>
#    ex: file/interpolate "^VARNAME=.*$" "VARNAME=value" "default.vars"
file/interpolate(){
  local pattern="$1"
  local replace="$2"
  local file="$3"
  local delim=${4:-"|"}

  if is/in_file "$pattern" "$file"; then
    file/sed_inplace "s${delim}$pattern${delim}$replace${delim}" "$file"
  else
    echo "$replace" >> "$file"
  fi
}
# shell-helpers - look up. climb tree. look down. look around.
#   https://github.com/briceburg/shell-helpers

#
# get/ returns single-value string
# find/ returns multi-value lists
#

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


# find/matching <pattern> <list items...>
#  returns a filtered list of items matching pattern.
find/filtered(){
  local pattern="$1" ; shift || true
  local item
  local found=false

  for item; do
    is/in "$pattern" "$item" && {
      echo "$item"
      found=true
    }
  done

  $found
}
# shell-helpers - git thingers
#   https://github.com/briceburg/shell-helpers


# usage: git/clone <repo-path-or-url> <destination>
git/clone(){
  local url="$1"
  local target="$2"
  prompt/overwrite "$target" || return 1

  [ -w $(dirname $target) ] || {
    p/warn "$target parent directory not writable"
    return 126
  }

  local flags=""
  if ! is/url "$url"; then
    [ -d "$url/.git" ] || {
      p/warn "$url is not a git repository"
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
    p/warn "$path is not a git repository."
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


# io/cat - allows io/ funcs to accept either piped input or a list of strings as
#          input. Try to use "-" as first argument to hint stdin.
#          normalizes output, one per-line.
#
# examples:
#   cat my-file | io/cat -   =>
#     <contents of my-file...>
#
#   io/cat "hello" "world" =>
#     hello
#     world
io/cat(){
  # if stdin hint, or we're piped to AND without arguments, read from stdin...
  if [ "$1" = "-" ] || [[ ! -t 0 && ${#@} -eq 0 ]]; then
    cat -
  else
    local line
    for line; do echo $line; done
  fi
}

# strips comments and blank lines
io/no-comments(){
  io/no-empty "$@" | sed -e '/^\s*[#;].*$/d'
}

# strips blank lines
io/no-empty(){
  io/cat "$@" | sed -e '/^\s*$/d'
}

# strips blank lines, as well as leading and trailing whitespace
io/trim(){
  io/cat "$@" | awk '{$1=$1};1'
}

# adds a prefix to items, returning the prefixed items first
# example: io/add-prefix "p" "a" "b" =>
#   pa
#   pb
#   a
#   b
io/add-prefix(){
  local prefix="$1" ; shift || true
  local item

  for item; do
    echo "$prefix$item"
  done

  [ -z "$prefix" ] && return
  io/add-prefix "" "$@"
}

io/lowercase(){
  io/cat "$@" | awk '{print tolower($0)}'
}
# shell-helpers - you put your left foot in, your right foot out.
#   https://github.com/briceburg/shell-helpers

is/absolute(){
  [[ "${1:0:1}" == / || "${1:0:2}" == ~[/a-z] ]]
}

# is/any <string|pattern> <list...>
#   case insensitive matching (lowercases string/pattern first)
#  use is/in as non-lowercasing alternative
is/any(){
  local pattern="$(io/lowercase "$1")" ; shift
  is/in "$pattern" "$@"
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

# is/in <pattern> <strings...>
#  returns true if a pattern matches _any_ string
#  supports wildcard matching
is/in(){
  #@TODO support piping of pattern

  local pattern="$1" ; shift || true
  local wildcard=false
  local item
  [[ "$pattern" == *"*"* ]] && wildcard=true

  for item; do
    if $wildcard; then
      [[ "$item" == $pattern ]] && return 0
    else
      [ "$item" = "$pattern" ] && return 0
    fi
  done

  return 1
}

# is/in_file <pattern> <file to search>
is/in_file(){
  local pattern="$1"
  local file="$2"
  grep -q "$pattern" "$file" 2>/dev/null
}

# is/in_list <item> <list items...>
#  returns true if <item> matches _any_ list item
is/in_list(){
  #@TODO support piping of item
  #@TODO disallow wildcard matching?

  is/in "$@"
}

# is/matching <string> <patterns...>
#  returns true if string matches _any_ pattern
is/matching(){
  #@TODO support piping of string

  local string="$1" ; shift || true
  local pattern
  for pattern; do
    is/in "$pattern" "$string" && return 0
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
    p/warn "refusing to fetch $url"
    return 1
  }

  if is/cmd $wget ; then
    $wget -qO - $url
  elif is/cmd $curl ; then
    $curl -Lfs $url
  else
    p/warn "unable to fetch $url" "missing both curl and wget"
    return 1
  fi
}

# shell/detect - detect user's shell and sets
#  __shell (user's shell, e.g. 'fish', 'bash', 'zsh')
#  __shell_file (shell configuration file, e.g. '~/.bashrc')
# usage: shell/detect [shell (skips autodetect)]
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
  p/warn "failed detecting shell config file, falling back to $__shell_file"
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

  p/comment \
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

# shell/is/in_path <path|pattern>
shell/is/in_path(){
  # trim trailing slash from path|pattern
  local pattern="$(echo "$1" | sed 's|/$||')"
  local IFS=":"

  is/in "$pattern" $PATH
}
# prompt/user - prompt for input, useful for assigning variiable values
# usage: prompt/user <prompt message> [fallback value*] [flags]
#   * uses fallback value if no input recieved or a tty is not available
# example:
#   name=$(prompt/user "name to encrypt")
#   port=$(prompt/user "port" 8080)
prompt/user(){
  local input=
  local prompt="${1:-value}"
  local default="$2"
  local read_flags="${3:--r}"
  [ -z "$default" ] || prompt+=" [$default]"

  # convert escape sequences in prompt to ansi codes
  prompt="$(echo -e -n "$prompt : ")"

  while [ -z "$input" ]; do
    # we have a tty or script is fed through stdin
    if [[ -t 0 || -z "${BASH_SOURCE[0]}" ]]; then
      read $read_flags -p "$prompt" input </dev/tty
    else
      read input
    fi

    [[ -n "$default" && -z "$input" ]] && input="$default"
    [ -z "$input" ] && p/warn "invalid input"
  done
  echo "$input"
}

# prompt/confirm - pause before continuing
# usage: prompt/confirm [message]
# examples:
#  prompt/confirm "really?" || exit 0
prompt/confirm() {
  local val
  while true; do
    val="$(prompt/user "${@:-Continue?} [y/n]" "" "-r -n 1")"
    echo
    case "$val" in
      [yY]) return 0 ;;
      [nN]) return 1 ;;
      *) p/warn "invalid input"
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
# shell-helpers - look up. climb tree. look down. look around.
#   https://github.com/briceburg/shell-helpers

#
# get/ returns single-value string
# find/ returns multi-value lists
#

# get/cmd - return first usable command, preferring __cmd_prefix versions
# usage: get/cmd <command(s)...>
# example:
#  ansible=$(__cmd_prefix=badevops- get/cmd ansible dansible) =>
#   1. "badevops-ansible"
#   2. "badevops-dansible"
#   3. "ansible"
#   4. "dansible"
#   5. "" - returns 127
get/cmd(){
  for cmd in $(io/add-prefix "$__cmd_prefix" "$@"); do
    type "$cmd" &>/dev/null || continue
    echo "$cmd"
    return 0
  done

  return 127
}

# usage: get/gid_from_name <group name>
get/gid_from_name(){
  if is/cmd getent ; then
    getent group "$1" | cut -d: -f3
  elif is/cmd dscl ; then
    dscl . -read "/Groups/$1" PrimaryGroupID 2>/dev/null | awk '{ print $2 }'
  else
    python -c "import grp; print(grp.getgrnam(\"$1\").gr_gid)" 2>/dev/null
  fi
}

# usage: get/gid_from_file <path>
get/gid_from_path(){
  ls -ldn "$1" 2>/dev/null | awk '{print $4}'
}
# shell-helpers - taming of the print
#   https://github.com/briceburg/shell-helpers

#
# printf outputs
#

p/error(){
  p/blockquote "\e[31m" "✖ " "$@" >&2
}

p/success(){
  p/blockquote "\e[32m" "✔ " "$@" >&2
}

p/notice(){
  p/blockquote "\e[33m" "➜ " "$@" >&2
}

p/log(){
  p/blockquote "\e[34m" "• " "$@" >&2
}

p/warn(){
  p/blockquote "\e[35m" "⚡ " "$@" >&2
}

p/comment(){
  printf '\e[90m# %b\n\e[0m' "$@" >&2
}

p/shout(){
  printf '\e[33m⚡\n⚡ %b\n⚡\n\e[0m' "$@" >&2
}

p/header(){
  printf "========== \e[1m$1\e[21m ==========\n"
}

p/blockquote(){
  local escape="$1" ; shift || true
  local prefix="$1" ; shift || true
  local indent="$(printf '%*s' ${#prefix})"

  while [ $# -ne 0 ]; do
    printf "$escape$prefix%b\n\e[0m" "$1"
    prefix="$indent"
    shift
  done
}
# @shell-helpers_UPDATE_URL=http://get.iceburg.net/shell-helpers/latest-v2/shell-helpers.sh
