
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
# usage: sed_inplace "file" "sed regex pattern"
#    ex: sed_inplace "/tmp/file" "s/CLIENT_CODE/ACME/g"
#    ex: sed_inplace "/tmp/file" "/pattern_to_remove/d"
#
sed_inplace(){
  local sed=
  local sed_flags="-r -i"

  for sed in gsed /usr/local/bin/sed sed; do
    type $sed &>/dev/null && break
  done

  [ "$sed" = "sed" ] && [[ "$OSTYPE" =~ darwin|macos* ]] && sed_flags="-i '' -E"
  $sed $sed_flags "$2" $1
}
