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

RUN curl -L https://github.com/docker/machine/releases/download/v0.8.1/docker-machine-Linux-x86_64 >/usr/local/bin/docker-machine && \
  chmod +x /usr/local/bin/docker-machine

ARG NAMESPACE
ENV \
  HOME="/$NAMESPACE/home"

RUN mkdir -p $HOME && \
  git config --global user.email "tests-container@$NAMESPACE.git" && \
  git config --global user.name "Tests Docker" && \
  chmod -R 777 $HOME

VOLUME $HOME
WORKDIR /$NAMESPACE

CMD bats tests/bats/
