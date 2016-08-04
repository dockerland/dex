#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_run(){
  cat <<-EOF

Piping hot docker executables to your door.

'dex run <image>' executes the program contained by <image> as if it were
locally installed. We call these images "docker executables" or "dexecutables".

Images are built from Dockerfiles kept in "source repositories" and managed
by 'dex remote' commands, or by editing the sources.list file in \$DEX_HOME.

Dex searches repository checkouts for <image> and executes the first found.
Limit the search by slash-passing a repository, e.g. <repo-name>/<image>, or
bypass it entirely using 'dex install'. 'dex update' refreshes checkouts.

'dex run' automatically builds <image> from its Dockerfile. This introduces a
delay when <image> is first run. Use 'dex image' to build and maintain images.

Usage: dex run [repository/]<image> [options]

  # Run a dexecutable (below examples run sed)
  dex run sed
  echo 'foo' | dex run sed s/foo/bar/
  dex run sed s/foo/bar/ <(echo 'foo')

  # Run a tagged version of a dexecutable (below maps to sed/Dockerfile.darwin)
  dex run sed:darwin -h

  # Run a dexecutable from a particular source repository
  dex run extra/gitk

Options:

  -h|--help             Display help
  -b|--build            Always build the image before executing
  -p|--persist          Persist the container after it exits
EOF
}
