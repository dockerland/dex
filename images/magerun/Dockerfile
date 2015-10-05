FROM alpine

RUN apk add --update \
    php-phar \
    php-cli \
    php-zlib \
    php-ctype \
    php-curl \
    php-xml \
    php-xmlreader \
    php-iconv \
    && rm -rf /var/cache/apk/*

RUN mkdir -p /workspace

RUN wget http://files.magerun.net/n98-magerun-latest.phar -O /usr/local/bin/n98-magerun.phar
RUN chmod +x /usr/local/bin/n98-magerun.phar

# ENV HOME="/tmp"
# USER nobody
WORKDIR /workspace

VOLUME /workspace

ENTRYPOINT ["n98-magerun.phar"]

CMD ["list"]
