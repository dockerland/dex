# FROM debian

# RUN apt-get update -qq && \
#   apt-get -yqq install gitk && \
#   apt-get -yqq clean
FROM alpine:edge

RUN apk add --update \
    git-gitk \
    ttf-droid \
    && rm -rf /var/cache/apk/*

RUN mkdir -p /workspace

# ENV HOME="/tmp"
# USER nobody
WORKDIR /workspace

VOLUME /workspace

ENTRYPOINT ["gitk"]
