FROM alpine:3.4

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
  apk add --update \
    bats \
  && rm -rf /var/cache/apk/*

VOLUME /tests

CMD ls -l /tests
