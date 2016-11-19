FROM alpine:3.4

LABEL org.dockerland.dex.api="v1"
CMD echo "ALPINE_RELEASE=$(cat /etc/alpine-release)" ; printenv

# bust some cache
ARG DEXBUILD_NOCACHE
RUN echo "I always execute"
