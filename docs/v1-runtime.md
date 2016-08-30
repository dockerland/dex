# dex v1-runtime

## work in progress

```sh
# label defaults -- images may provide a org.dockerland.dex.<var> label
#  supplying a value that overrides these default values, examples are:
#
#  org.dockerland.dex.docker_devices=/dev/shm   (shm mounted as /dev/shm)
#  org.dockerland.dex.docker_envars="LANG TERM" (passthru LANG & TERM)
#  org.dockerland.dex.docker_flags=-it          (interactive tty)
#  org.dockerland.dex.docker_home=~             (user's actual home)
#  org.dockerland.dex.docker_volumes=/etc/hosts:/etc/hosts:ro
#  org.dockerland.dex.docker_workspace=/        (host root as /dex/workspace)
#  org.dockerland.dex.window=true               (applies window/X11 flags)
#
```
