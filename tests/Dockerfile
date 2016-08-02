FROM alpine:3.4

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories ; \
  apk add --update \
    bash \
    bats \
    fish \
    git \
    make \
    mksh \
    zsh \
  && rm -rf /var/cache/apk/*

VOLUME /dex
WORKDIR /dex

CMD bats tests/bats/
