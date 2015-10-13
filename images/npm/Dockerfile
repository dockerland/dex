FROM alpine

RUN apk add --update \
    nodejs \
    && rm -rf /var/cache/apk/*

RUN mkdir -p /workspace
RUN mkdir -p /.npm && chmod 777 /.npm

WORKDIR /workspace

VOLUME /workspace
VOLUME /.npm

RUN npm install -g npm

ENTRYPOINT ["npm"]

CMD ["--help"]
