# dex v1-runtime

## work in progress

lets talk about how to "dexify" your application...

* TBD
  * labeling / api versioning
  * Windowed/X11 examples
  * # by default, LANG and TZ are passed-through to container


```sh
# label defaults -- images may provide a org.dockerland.dex.<var> label
#  supplying a value that overrides these default values, examples are:
#
#  org.dockerland.dex.docker_devices=/dev/shm   (shm mounted as /dev/shm)
#  org.dockerland.dex.docker_envars="LANG TERM !MYAPP_" (passthru LANG & TERM & MYAPP_*)
#  org.dockerland.dex.docker_flags=-it          (interactive tty)
#  org.dockerland.dex.docker_groups=tty         (adds 'tty' to container user)
#  org.dockerland.dex.docker_home=~             (user's actual home)
#  org.dockerland.dex.docker_volumes=/etc/hosts:/etc/hosts:ro
#  org.dockerland.dex.docker_workspace=/        (host root as /dex/workspace)
#  org.dockerland.dex.host_paths=rw             (rw mount host HOME and CWD)
#  org.dockerland.dex.host_users=ro             (ro mount host /etc/passwd|group)
#  org.dockerland.dex.window=yes                (applies window/X11 flags)
#
```
