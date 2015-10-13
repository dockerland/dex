FROM alpine

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

RUN apk add --update \
    the_silver_searcher@testing \
    && rm -rf /var/cache/apk/*

RUN mkdir -p /workspace

WORKDIR /workspace

VOLUME /workspace

ENTRYPOINT ["ag"]
