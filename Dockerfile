FROM golang:alpine3.9 AS build

ENV WEBHOOK_VERSION=2.6.9 WEBHOOK_CHECKSUM=8a419a9796e0d7368dc52c53125d51aa1d28974269fe614eb7a91886fa41eb40

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

FROM alpine:3.9
COPY --from=build /usr/local/bin/webhook /usr/local/bin/webhook

EXPOSE 9000

CMD ["/usr/local/bin/webhook", "-verbose", "-hotreload", "-hooks", "/hooks.json"]
