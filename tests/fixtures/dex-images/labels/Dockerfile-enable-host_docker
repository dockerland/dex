FROM alpine:3.4

RUN apk add --no-cache curl

#
# v1 dex-api
#

LABEL \
  org.dockerland.dex.api="v1" \
  org.dockerland.dex.host_docker=rw

#
# debian image
#

CMD curl --unix-socket /var/run/docker.sock http://localhost/info
