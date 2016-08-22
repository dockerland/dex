FROM debian:jessie

#
# v1 dex-api
#

LABEL \
  org.dockerland.dex.api="v1" \
  org.dockerland.dex.docker_devices="tty0 /dev/console" \
  org.dockerland.dex.docker_flags="--tty -e TESTVAR=TEST" \
  org.dockerland.dex.docker_home="/tmp/dex-tests/tmp/home" \
  org.dockerland.dex.docker_workspace="/tmp/dex-tests/tmp/workspace" \
  org.dockerland.dex.docker_volumes="/tmp/dex-tests/tmp/vol /tmp/dex-tests/tmp/vol:/tmp/ro:ro"

#
# debian image
#

CMD echo "DEBIAN_RELEASE=$(cat /etc/debian_version)" ; printenv
