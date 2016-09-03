FROM debian:jessie

#
# v1 dex-api
#

LABEL \
  org.dockerland.dex.api="v1" \
  org.dockerland.dex.docker_home="~" \
  org.dockerland.dex.docker_volumes="~:/realhome:ro"


#
# debian image
#

CMD echo "DEBIAN_RELEASE=$(cat /etc/debian_version)" ; printenv
