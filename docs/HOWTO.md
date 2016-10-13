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

The process is no different than providing a regular Dockerfile for your application, except that
* dex uses _labels_ to specify runtime behavior and runtime version
* dex uses a runtime script to execute your image (for consistency and convenience)


For instance, setting the `org.dockerland.dex.docker_devices=/dev/shm`
label will mount the host's /dev/shm into your application container at runtime.
You may also pass arbitrary flags to `docker run` via the `org.dockerland.dex.docker_flags` label.  E.g.

```
FROM debian:jessie

#
# dex my-app:latest image
#

# ... commands to install my-app and all dependencies

#
# v1 dex-api
#

LABEL \
  org.dockerland.dex.api="v1" \
  org.dockerland.dex.docker_flags="--interactive --tty" \
  org.dockerland.dex.docker_devices=/dev/shm
```


Refer to [v1-runtime documentation](v1-runtime.md) for a list of behavior-changing
 labels and conventions.

#### getting started


To execute your application with dex, the Dockerfile must be in a [source repository](../README.md#source-repositories).



##### create a local source repository

Lets create a local development repository. Alternatively you can start
working directly from a repository checkout (in `$DEX_HOME/checkouts/`).

```sh

# initialize local repository with Dockerfile for "my-app"
mkdir -p /path/to/my/local-repo
cd /path/to/my/local-repo
git init
mkdir -p dex-images/my-app
cp /path/to/my-app/Dockerfile dex-images/my-app/Dockerfile
echo "LABEL org.dockerland.dex.api=\"v1\"" >> dex-images/my-app/Dockerfile
git add dex-images
git commit -m "dexified my-app"

# add local repository to dex
dex source add local /path/to/my/local-repo
```

the "local" repository is now checked out to `~/.dex/checkouts/local/`


##### testing / running your application

> To speed up development, it is recommended to work within a checkout of a source repository. This way you do not need to
commit and --pull changes whenever they're made -- the changes are immediately
available.

example of testing changes _from a checkout_

```sh
cd ~/.dex/checkouts/local/my-app
echo "# my changes" >> Dockerfile
dex run --build local/my-app
```

example of testing changes  _from a repository_ (requires intermittent commit)

```sh
cd /path/to/my/local-repo
echo "# my changes" >> Dockerfile
git commit -am "my changes"
dex run --pull local/my-app
```


#### busting cache

Often, images will use a git repository to install an application. E.g.

```
# ...
RUN git clone my-repo/my-app.git /app
# ...
```

Docker will cache this, and use it's cache for subsequent builds -- no matter
if the git repository and application code has been changed upstream. To get
around this, dex builds images with a CACHE_BUST argument. Use this to introduce
randomness and force the git clone command. E.g.

```
# ...
ARG CACHE_BUST
RUN git clone my-repo/my-app.git /app
# ...
```

For an example, see our test [cachebust Dockerfiles](../tests/fixtures/dex-images/cachebust)
