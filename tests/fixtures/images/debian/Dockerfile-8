FROM debian:jessie

#
# v1 dex-api
#
ENV \
  DEX_API="v1" \
  HOME="/dex/home" \
  WORKSPACE="/dex/workspace"

RUN mkdir -p $HOME $WORKSPACE
VOLUME /dex

#
# debian image
#

CMD echo "DEBIAN_RELEASE=$(cat /etc/debian_version)" ; printenv
