FROM alpine:3.4

RUN echo "@testing http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories ; \
  apk add --update \
    bash \
    bats@testing \
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

RUN chmod o+w /etc/passwd /etc/group && \
  printf "#!/usr/bin/env sh\n\
  echo \"$NAMESPACE:x:\$(id -u):$(id -g):gecos:$HOME:/bin/sh\" >> /etc/passwd\n\
  echo \"$NAMESPACE:x:\$(id -g):\" >> /etc/group\n\
  exec \$@\n" > /entrypoint.sh && chmod +x /entrypoint.sh

VOLUME $HOME
WORKDIR /$NAMESPACE

ENTRYPOINT ["/entrypoint.sh"]
CMD bats tests/bats/
