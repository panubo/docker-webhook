FROM golang:1.14-alpine3.12 AS build

ENV WEBHOOK_VERSION=2.8.0 WEBHOOK_CHECKSUM=c521558083f96bcefef16575a6f3f98ac79c0160fd0073be5e76d6645e068398

WORKDIR /go/src/github.com/adnanh/webhook

RUN apk add --no-cache --update -t build-deps curl go git gcc libc-dev libgcc \
  && curl -sSf -L https://github.com/adnanh/webhook/archive/${WEBHOOK_VERSION}.tar.gz -o webhook.tgz \
  && printf "%s  %s\n" "${WEBHOOK_CHECKSUM}" "webhook.tgz" > CHECKSUM \
  && sha256sum webhook.tgz \
  && ( sha256sum -c CHECKSUM; ) \
  && tar --strip 1 -xzf webhook.tgz \
  && go get -d \
  && go build -o /usr/local/bin/webhook \
  && apk del --purge build-deps \
  && rm -rf /var/cache/apk/* \
  && rm -rf /go

FROM alpine:3.12
EXPOSE 9000
COPY --from=build /usr/local/bin/webhook /usr/local/bin/webhook

RUN apk --no-cache --update add bash curl git wget jq ca-certificates \
  && addgroup -g 1000 webhook \
  && adduser -D -u 1000 -G webhook webhook \
  && rm -rf /var/cache/apk/*

USER webhook
CMD ["/usr/local/bin/webhook", "-verbose", "-hotreload", "-hooks", "/hooks.json"]
