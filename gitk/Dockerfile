FROM debian

RUN apt-get update -qq && \
  apt-get -yqq install gitk && \
  apt-get -yqq clean

RUN mkdir -p /workspace


# ENV HOME="/tmp"
# USER nobody
WORKDIR /workspace

VOLUME /workspace

ENTRYPOINT ["gitk"]
