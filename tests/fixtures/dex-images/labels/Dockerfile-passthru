FROM debian:jessie

#
# v1 dex-api
#

LABEL \
  org.dockerland.dex.api="v1" \
  org.dockerland.dex.docker_envars="TEST_* TZ LANG"

#
# debian image
#

CMD echo "DEBIAN_RELEASE=$(cat /etc/debian_version)" ; printenv
