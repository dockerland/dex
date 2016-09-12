#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_source(){
  cat <<-EOF

Piping hot docker executables to your door.

"dexecutables" are images built and executed from Dockerfiles contained within
git "source repositories" defined in \$DEX_HOME/sources.list.

The sources.list file lists repositories, one per line, in space-delimited
"<name> <url>" format. "name" must be alphanumeric and "url" must be the
repository URL (remote or a local path). E.g.

  reponame git@github.com:User/reponame.git
  reponame /path/to/reponame

Repositories are cloned under \$DEX_HOME/checkouts. If a local path is used,
a shared clone will be made.

Removing or adding repositories will not effect built images, allowing
installed dexecutables to function as normal. Use the "dex image" command to
manage images built from sources.

Usage: dex source <command> [options]

  # Add an additional dexecutable source repository named "extras"
  dex source add extras git@github.com:dockerland/dex-dockerfiles-extra.git

Commands:

  add <name> <url>       Add (and pulls) a dexecutable source repository.
  pull [sourcestr]       Pull (refresh) sources, optionally matching name || url
  rm <sourcestr>         Remove source repository matching name || url.
  ls                     List available source repositories

* <sourcestr> is a multi-form string written as <name|url|'*'> and is used to
  lookup source(s) by name, url, or wildcard ('*') to match all.

Options:

  -h|--help|help        Display help
  -f|--force            When removing or pulling, discard working copy changes
                        When adding, first remove any matching name

EOF
}
