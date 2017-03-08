# dex v1-runtime

The dex runtime is responsible for consistently executing application containers
by passing flags `docker run`.

As an example, the runtime passes the `--user $CURRENT_UID:$CURRENT_GID` flag so that dex application containers always execute under the _current user and group_. This ensures after-effects (e.g. a git checkout to a bind mount) are owned by the executing user,
as you would expect if `git` was system installed. See [default behavior](#default-behavior) for more on runtime defaults.

* Image labels override or augment default runtime behavior, and are defined by _tool authors_ in Dockerfiles. E.g. the `org.dockerland.dex.window` label toggles X11 support for a GUI application.
* In addition to labels, environmental variables impacting behavior may be passed by _tool users_ at runtime. For instance `DEX_DOCKER_ENTRYPOINT=bash dex run sed` will drop into the bash shell of the `extra/sed` application container instead of running sed.

The runtime is an [accessible bash script](https://github.com/dockerland/dex/blob/master/lib.d/v1-runtime.sh) -- please read it if you're interested in how dex works.


## runtime labels

> * space-separate values for labels supporting multiple values
* labels supporting paths values allow /host-path:/container-path:ro|rw format as well as /path

label | description
--- | ---
`org.dockerland.dex.docker_devices` | named devices are bind mounted into the container (only if they exist on host). E.g. `org.dockerland.dex.docker_devices="shm dri snd"`
`org.dockerland.dex.docker_envars` | specified variables are passed through from host environment to container. defaults to `"LANG TZ"` supports wildcards, e.g. `"LANG TZ DOCKER_*"`
`org.dockerland.dex.docker_flags` | arbitrary runtime flags, e.g. `org.dockerland.dex.docker_flags="-p 7777:80 --memory 256mb"`
`org.dockerland.dex.docker_groups` | add named groups to container user via `docker run --group-add` mechanism
`org.dockerland.dex.docker_home` | host directory to bind-mount to /dex/home in container. set to `~` to use the executing user's real home directory. defaults to a unique home per application (see [default behavior](#default-behavior))
`org.dockerland.dex.docker_volumes` | named paths are bind mounted into the container (only if they exist on host). E.g. `org.dockerland.dex.docker_volumes="/etc/hosts:/etc/hosts:ro /tmp:/host/tmp"`
`org.dockerland.dex.docker_workspace` | host directory to bind-mount as containers CWD. Some images (like [dosemu2](https://github.com/briceburg/docker-dosemu2/blob/01433015360840d99cfd9d7283ddf71e88e928d6/Dockerfile-dex-v1#L35)) use `'/'` to mount the host root to /dex/workspace in order to access the entire host filesystem, and rely on the `DEX_HOST_PWD` environmental variable in an entrypoint to adjust.
`org.dockerland.dex.host_docker` | `(empty, 'rw', or 'rw')` bind mounts the host's docker socket into container under /var/run/docker.sock. Also adds the user to the host's docker group and passes through DOCKER_* and MACHINE_STORAGE_PATH envars.
`org.dockerland.dex.host_paths` | `('ro', empty, or 'rw')` bind mounts the real user's home directory and host's currenty directory (only if it's safe, e.g. not in /etc or /sbin or a directory that may impact container execution). defaults to `ro`. This label aids in common path resolutions (e.g. allows reads to absolute paths referencing files under the user's real home).
`org.dockerland.dex.host_users` | `(empty, 'rw', or 'rw')` augment the /etc/passwd and /etc/group files in the container with current current user (if the uid/gid don't already exist). Helpful if you're seeing unknown user/id errors.
`org.dockerland.dex.window` | `(empty, 'yes', 'true', 'on', 'no/false/off')` setting truthy enables X11 mode which attempts to allow GUI applications to seamlessly communicate with the host's X11 socket and auth. See the [xeyes](https://github.com/dockerland/dex-dockerfiles-extra/tree/master/dex-images/xeyes) demo app for more on X11.

## runtime variables

> variables apply to installed 'dexecutables' as well as `dex run`. E.g. `DEX_DEBUG=true dsed` as well as `DEX_DEBUG=true dex run sed`.

variable | default | description
--- | --- | ---
`DEX_DOCKER_CMD` | | alternative command passed to docker run
`DEX_DOCKER_ENTRYPOINT` | | alternative entrypoint passed to docker run
`DEX_DOCKER_FLAGS` | | arbitrary flags passed to
`DEX_DOCKER_HOME` | ~/.dex/homes/APP_NAME | host directory mounted as container's \$HOME
`DEX_DOCKER_WORKSPACE` | $(pwd) | host directory mounted as container's CWD
`DEX_DOCKER_GID` | current user GID | GID to run container as
`DEX_DOCKER_UID` | current user UID | UID to run container as
`DEX_DOCKER_LOG_DRIVER` | none | container log driver
`DEX_PERSIST` | false | persist container after it exits


## default behavior

flag | description | override
--- | --- | ---
`--rm` | removes container after it exits | set DEX_PERSIST or pass the --persist flag to `dex run`
`-e LANG=$LANG -e TZ=$TZ` | passthrough current environment LANG and TZ vars | `docker_envars` label --persist flag to `dex run` or set `DEX_PERSIST=true`
`-v ~/.dex/homes/NAME-TAG:/dex/home` | mounts a unique home directory for application under /dex/home | `docker_home` label or `DEX_DOCKER_HOME` var
`-v $(pwd):/dex/workspace` | mounts host current directory under /dex/workspace in container | `docker_workspace` label or `DEX_DOCKER_WORKSPACE` var
`-v ~:~:ro` | readonly mount user's real home in an effort to aid common path resolutions | `host_paths` label
`-u $CURRENT_UID:$CURRENT_GID` | run container under current UID/GID | `DEX_DOCKER_UID` and `DEX_DOCKER_GID` variables.
`-e  HOME=/dex/home` | seeds HOME envar | none
`--workdir=/dex/workspace` | start in /dex/workspace (which has host's CWD mounted) | none

---

in addition, information about the application container image and host system are made available to the container via the following environmental variables;

var | description
--- | ---
`DEX_DOCKER_HOME` | directory (on host) bind-mounted to /dex/home
`DEX_DOCKER_WORKSPACE` | directory (on host) bind-mounted to /dex/workspace
`DEX_HOST_GID` | GID of host user
`DEX_HOST_UID` | UID of host user
`DEX_HOST_GROUP` | Primary Group name of host user
`DEX_HOST_USER` | Name of host user
`DEX_HOST_PWD` | pwd (on host) where container was spawned
`DEX_HOST_HOME` | Home directory (on host) of host user
`DEX_IMAGE` | repotag of application container image (e.g. `extra/sed:latest`)
`DEX_IMAGE_NAME` | application container image name (e.g. `sed`)
`DEX_IMAGE_TAG` | application container image tag (e.g. `macos` or `latest`)
