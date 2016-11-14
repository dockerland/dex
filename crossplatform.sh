
# get_group_id accepts <group_name> and outputs group id, empty if not found.
get_group_id(){
  if type getent &>/dev/null; then
    getent group $1 | cut -d: -f3
  elif type dscl &>/dev/null; then
    dscl . -read /Groups/$1 PrimaryGroupID 2>/dev/null | awk '{ print $2 }'
  else
    python -c "import grp; print(grp.getgrnam(\"$1\").gr_gid)" 2>/dev/null
  fi
}


# sed_inplace : in place file substitution
############################################
#
# usage: sed_inplace "file" "sed substitution"
#    ex: sed_inplace "/tmp/file" "s/CLIENT_CODE/BA/g"
#
sed_inplace(){
  # linux
  local __sed="sed"

  if [[ "$OSTYPE" == darwin* ]] || [[ "$OSTYPE" == macos* ]] ; then
    if $(type gsed >/dev/null 2>&1); then
      local __sed="gsed"
    elif $(type /usr/local/bin/sed >/dev/null 2>&1); then
      local __sed="/usr/local/bin/sed"
    else
      sed -i '' -E "$2" $1
      return
    fi
  fi

  $__sed -r -i "$2" $1
}
