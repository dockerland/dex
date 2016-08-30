# dex FAQ

## exec ____ instead of the contained application

dex supports altering the default [docker entrypoint](https://docs.docker.com/engine/reference/builder/#/entrypoint) to run, for instance, a shell instead of the default application.

Override the entrypoint via:
  * passing a flag to `dex run`, or
  * the `DEX_DOCKER_ENTRYPOINT` environmental variable, helpful for **installed** dexecutables.

For some dexecutables, you may need to clear the [docker command](https://docs.docker.com/engine/reference/builder/#/cmd) and force an interactive tty to get a shell.

```sh

# via dex run
dex run --entrypoint sh ansible-playbook

# via environmental variable
DEX_DOCKER_ENTRYPOINT=sh dansible-playbook

# force interactive tty and clear cmd
DEX_DOCKER_ENTRYPOINT=sh DEX_DOCKER_FLAGS="-it" DEX_DOCKER_CMD= dansible-playbook
```

## containerize your application

dex runs your application with the [v1-runtime](v1-runtime.md)

lets talk about how to "dexify" your application...


```sh
dex source add dev /path/to/my-dex-repo

# the hard way to test changes (requires pushing a commit)
echo "# my changes" >> /path/to/my-dex-repo/images/my-app/Dockerfile
( cd /path/to/my-dex-repo && git commit -am "updated repo" )
dex run --pull dev/my-app

# recommended alternative while developing
echo "# my changes" >> ~/.dex/checkouts/dev/my-app/Dockerfile
#  ^^^ source repositories are checked out to $DEX_HOME/checkous/<name>
dex run --build dev/my-app

```

* TBD
  * labeling / api versioning
  * Windowed/X11 examples
  * org.dockerland.dex.docker_home labels, non absolute path relative to $DEX_HOME/<api>-homes/<label>
