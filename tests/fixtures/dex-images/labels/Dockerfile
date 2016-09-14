FROM debian:jessie

#
# v1 dex-api
#

LABEL \
  org.dockerland.dex.api="v1" \
  org.dockerland.dex.docker_devices="tty0 /dev/console" \
  org.dockerland.dex.docker_envars="BATS_TESTVAR" \
  org.dockerland.dex.docker_flags="--tty -e TESTVAR=TEST" \
  org.dockerland.dex.docker_groups="tty" \
  org.dockerland.dex.docker_home="\$TMPDIR/label-test/home" \
  org.dockerland.dex.docker_workspace="\$TMPDIR/label-test/workspace" \
  org.dockerland.dex.docker_volumes="\$TMPDIR/label-test/vol \$TMPDIR/label-test/vol:/tmp/ro:ro"

#
# debian image
#

CMD echo "DEBIAN_RELEASE=$(cat /etc/debian_version)" ; printenv
