FROM alpine

RUN apk add --update \
    nodejs \
    && rm -rf /var/cache/apk/*

RUN mkdir -p /workspace

WORKDIR /workspace

VOLUME /workspace

ENTRYPOINT ["node"]

CMD ["--help"]
