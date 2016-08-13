#
# lib.d/display_help.sh for dex -*- shell-script -*-
#

display_help_run(){
  cat <<-EOF

Piping hot docker executables to your door.

'dex run <imagestr>' executes images as if the contained application was locally
installed. We call these images "docker executables" or "dexecutables".

Images are built from Dockerfiles kept in "source repositories" in the
\$DEX_HOME/sources.list file and managed by the 'dex source' command.

Dex run searches images from source checkouts matching <imgstr> and executes the
first found. Limit searching by slash-passing a source and/or tag. Using
'dex install' will bypass it entirely.

'dex run' will automatically build the matching image from its Dockerfile on
first run -- introducing a delay. Use 'dex image' to build and maintain images.

Usage: dex run <imgstr>* [options]

  # Run a dexecutable (below examples run sed)
  dex run sed
  echo 'foo' | dex run sed s/foo/bar/
  dex run sed s/foo/bar/ <(echo 'foo')

  # Run a tagged version of a dexecutable (below maps to sed/Dockerfile.darwin)
  dex run sed:darwin -h

  # Run a dexecutable from a particular source repository
  dex run extra/gitk

* <imgstr> is a multi-form string defined as "[source/]<image[*]>[:tag]" and is
  used to lookup image(s), optionally filtering by source name and/or tag

Options:

  -h|--help             Display help
  -b|--build            Always build the image before executing
  -p|--pull             Refresh checkout(s) before executing, implies --build
  --persist             Persist the container after it exits

EOF
}
