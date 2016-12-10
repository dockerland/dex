p/help_run(){
  cat <<-EOF

dex - run applications without installing them or their dependencies.

About run:

Dex searches repository checkouts for a matching image and executes the first
found. Limit searching by passing a repo and/or tag.

Dex builds images the first time they are run -- introducing a delay. Use 'dex
install' to circumvent this. Force a re-build by passing --build or --pull.

Usage:
  dex run [options...] <[repository]/image[:tag]...>

Options:
  -h|--help
    Displays help
  -b|--build
    Force a re-build
  -p|--pull
    Force a rebuild, and pull (refresh) repositories.
  --persist
    Persist the container (do not remove it after it exits)
  -i|-t|-it|--interactive
    Force an interactive TTY
  --cmd <cmd>
    Provide an alternative CMD
  --entrypoint <entrypoint>
    Provide an alternative ENTRYPOINT
  --home <path>
    Provide an alternative home directory (on the host machine)
    Defaults to $DEX_HOME/homes/<image> (or what is provided by container label)
  --log-driver <driver>
    Provide an alternative log driver
    Defaults to none (or what is provided by container label)
  --gid|--group <gid>
    Provide an alternative GID to run container as
  --uid|--user <uid>
    Provide an alternative UID to run container as
  --workspace <path>
    Provide an alternative workspace directory (on the host machine)
    Defaults to CWD ($(pwd))

Examples:
  dex run debian ls
  dex run ag "the quick brown fox"
  dex run extra/gitk
  dex run sed:macos -h

  # piping and redirection
  echo 'foo' | dex run sed s/foo/bar/
  dex run sed s/foo/bar/ <(echo 'foo')
EOF
}
