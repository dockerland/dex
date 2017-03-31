FROM alpine:3.4

RUN apk add --no-cache \
    bash \
    curl \
    docker \
    fish \
    git \
    make \
    mksh \
    openssh \
    openssl \
    zsh \
  && git clone --depth 1 https://github.com/sstephenson/bats.git /tmp/bats && \
     /tmp/bats/install.sh /usr/local && rm -rf /tmp/bats

ARG NAMESPACE
ENV \
  HOME="/$NAMESPACE/home"

RUN mkdir -p $HOME && \
  git config --global user.email "tests-container@$NAMESPACE.git" && \
  git config --global user.name "Tests Docker" && \
  chmod -R 777 $HOME && \
  printf "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n" >> \
    /etc/ssh/ssh_config

# register executing user's uid and gid at runtime
RUN chmod o+w /etc/passwd /etc/group && \
  printf "#!/usr/bin/env sh\n\
  echo \"$NAMESPACE:x:\$(id -u):$(id -g):gecos:$HOME:/bin/sh\" >> /etc/passwd\n\
  echo \"$NAMESPACE:x:\$(id -g):\" >> /etc/group\n\
  exec \$@\n" > /entrypoint.sh && chmod +x /entrypoint.sh

VOLUME $HOME
WORKDIR /$NAMESPACE

ENTRYPOINT ["/entrypoint.sh"]
CMD bats tests/bats/
