FROM alpine:3.4

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories ; \
  apk add --update \
    bash \
    bats \
    docker \
    fish \
    git \
    make \
    mksh \
    openssl \
    zsh \
  && rm -rf /var/cache/apk/*

ENV \
  HOME="/tmp/dex-tests/home"

VOLUME /dex
WORKDIR /dex

CMD bats tests/bats/
