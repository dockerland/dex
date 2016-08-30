# dex FAQ

## exec ____ instead of the dexified application

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
