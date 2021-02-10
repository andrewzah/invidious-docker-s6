FROM crystallang/crystal:0.36.0-alpine-build as builder

RUN apk update --no-cache \
  && apk add --no-cache \
    curl \
    git \
    musl-dev \
    sqlite-static \
    zlib-dev

RUN crystal --version

ENV INVIDIOUS_VERSION "0.20.1"

WORKDIR /tmp
RUN git clone https://github.com/iv-org/invidious.git
  #&& cd invidious \
  #&& git checkout "$INVIDIOUS_VERSION" // currently breaks for zlib

WORKDIR /tmp/invidious
RUN shards install \
  && curl -Lo ./lib/lsquic/src/lsquic/ext/liblsquic.a https://github.com/iv-org/lsquic-static-alpine/releases/download/v2.18.1/liblsquic.a \
  && crystal build ./src/invidious.cr \
    --static --warnings all \
    --link-flags "-lxml2 -llzma"

FROM andrewzah/base-alpine:3.13

WORKDIR /app
RUN apk update --no-cache \
  && apk add --no-cache \
    bash \
    curl \
    librsvg \
    ttf-opensans

COPY --from=builder /tmp/invidious/config/ /app/config/
COPY --from=builder /tmp/invidious/locales/ /app/locales/
COPY --from=builder /tmp/invidious/assets /app/assets/
COPY --from=builder /tmp/invidious/invidious /usr/bin/invidious

COPY ./root/ /

HEALTHCHECK CMD ["curl", "-f", "http://localhost:3000/"]
