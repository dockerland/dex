# dex FAQ

## exec ____ instead of the contained application

Dex supports altering the default [docker entrypoint](https://docs.docker.com/engine/reference/builder/#/entrypoint), allowing a user to run applications other than the default, for instance, a shell.

Override the entrypoint via:
  * passing as a flag to `dex run`, e.g. `dex run --entrypoint=bash sed`, or
  * providing the `DEX_DOCKER_ENTRYPOINT` environmental variable (helpful for **installed** dexecutables). See [v1 runtime variables](v1-runtime.m2#runtime-variables) for more.

For some dexecutables, you may need to clear the [docker command](https://docs.docker.com/engine/reference/builder/#/cmd) and force an interactive tty to get a shell.

```sh
# force interactive tty and clear cmd
DEX_DOCKER_ENTRYPOINT=sh DEX_DOCKER_FLAGS="-it" DEX_DOCKER_CMD= dansible-playbook
```

## containerize your application

The process is no different than providing a regular
Dockerfile for your application, with the following exceptions:
* dex uses _[special labels](v1-runtime.md#runtime-labels)_ to specify runtime behavior and version
* dex generates a runtime script to execute your image (for consistency and convenience). It applies the working directory, users, groups, devices, volumes, variables, &c. needed to run your application.

If you have already containerized your application, all you need to do is add
label(s to support dex.

Refer to [v1-runtime documentation](v1-runtime.md) for a list of behavior-changing
 labels and conventions.

Here's a simple example from the [xeyes](https://github.com/dockerland/dex-dockerfiles-extra/tree/master/dex-images/xeyes) Dockerfile;

```Dockerfile
FROM alpine:edge
RUN apk add --no-cache xeyes
ENTRYPOINT ["xeyes"]

#
# v1 dex-api
#

LABEL \
  org.dockerland.dex.api="v1" \
  org.dockerland.dex.window="true"
```

### developing your dex application

##### create a local source repository

To run your application with dex, its Dockerfile must be in a [source repository](usage.md#source-repositories).

Lets create a local development repository. _Alternatively_ you can start
working directly from a repository that's already checked out (e.g. `~/.dex/checkouts/core`).

```sh
# initialize local repository
mkdir -p /path/to/my/local-repo
cd /path/to/my/local-repo
git init
```

##### add your application's Dockerfile

Lets pretend your application is named "my-app". We'll create its Dockerfile under `dex-images/my-app/`.

```sh
# use /path/to/my-app/Dockerfile for my application
cd /path/to/my/local-repo
mkdir -p dex-images/my-app
cp /path/to/my-app/Dockerfile dex-images/my-app/Dockerfile
echo "LABEL org.dockerland.dex.api=v1" >> dex-images/my-app/Dockerfile
git add dex-images
git commit -m "dexified my-app"
```

Dex will use this Dockerfile to build your application
image when it runs via `dex run my-app` or `dex image build my-app`.

Refer to [v1-runtime documentation](v1-runtime.md) for a list of dex specific labels you can use in your Dockerfile.

##### add a tagged Dockerfile [optional]

You may provide different versions of your application by naming the
Dockerfile `Dockerfile-<tag>`. For instance, provide a "debian-sid" version of your app by naming your Dockerfile `Dockerfile-debian-sid`. Users execute this version via `dex run my-app:debian-sid` &c.

> For applications with different versions, the Dockerfile is often a _symlink_
to a versioned Dockerfile acting as the default.

```sh
# tag my application as "debian-sid"
cd /path/to/my/local-repo/dex-images/my-app
mv Dockerfile Dockerfile-debian-sid

# make "debian-sid" the default version
ln -s Dockerfile-debian-sid Dockerfile

git add Dockerfile Dockerfile-debian-sid
git commit -m "versioned my-app"
```

##### register your local source repository

Before dex can execute `my-app`, we must first add our local source repository.
Skip this step if you're working from an existing checkout.

```sh
# add local repository to dex
dex repo add local /path/to/my/local-repo
```

the "local" repository is now checked out to `~/.dex/checkouts/local/`


##### run and test your application

> To speed up development, it is recommended to work within a checkout of a source repository. This way you do not need to
commit and --pull changes whenever they're made -- the changes are immediately
available.

example of testing changes _from a checkout_ (preferred)

```sh
cd ~/.dex/checkouts/local/dex-images/my-app
echo "# my changes" >> Dockerfile
dex run --build local/my-app
```

example of testing changes  _from a repository_ (requires intermittent commit)

```sh
cd /path/to/my/local-repo/dex-images/my-app
echo "# my changes" >> Dockerfile
git commit -am "my changes"
dex run --pull local/my-app
```


#### busting cache ( DEXBUILD_NOCACHE )

Sometimes images will use a git repository to install an application. E.g.

```
# ...
RUN git clone my-repo/my-app.git /app
# ...
```

The command is fingerprinted and its results cached in Docker's build-cache.
On subsequent builds the command fingerprint maintains the same, so Docker
returns the results from the build-cache. Your application code WILL NOT CHANGE
no matter if changes have been made upstream.

Dex provides a convenient way around this cache. Invoke the `DEXBUILD_NOCACHE`
build argument and _all_ subsequent commands will have a changed fingerprint --
and thus execute.

```
# ...
# bust the cache so git clone (and ALL subsequent commands) runs
ARG DEXBUILD_NOCACHE
RUN git clone my-repo/my-app.git /app
# ...
```

For an example, see our test [cachebust Dockerfiles](../tests/fixtures/dex-images/cachebust)
