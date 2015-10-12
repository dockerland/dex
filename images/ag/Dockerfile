FROM debian

RUN apt-get update -qq && \
  apt-get -yqq install silversearcher-ag && \
  apt-get -yqq clean

RUN mkdir -p /workspace

WORKDIR /workspace

VOLUME /workspace

ENTRYPOINT ["ag"]
