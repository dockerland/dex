FROM alpine:3.4

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories ; \
  apk add --update \
    bash \
    bats \
    curl \
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

RUN curl -L https://github.com/docker/machine/releases/download/v0.8.1/docker-machine-Linux-x86_64 >/usr/local/bin/docker-machine && \
  chmod +x /usr/local/bin/docker-machine

VOLUME /dex
WORKDIR /dex

CMD bats tests/bats/
