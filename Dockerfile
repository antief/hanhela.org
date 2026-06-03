# syntax=docker/dockerfile:1.7

ARG HUGO_VERSION=0.160.1
ARG NGINX_IMAGE=nginxinc/nginx-unprivileged:1.27-alpine

FROM hugomods/hugo:${HUGO_VERSION} AS builder
WORKDIR /src

ARG HUGO_BASEURL=/

# Hugo Modules require Go module metadata.
COPY go.mod ./
COPY go.sum ./
COPY config ./config
COPY archetypes ./archetypes
COPY assets ./assets
COPY content ./content
COPY layouts ./layouts
COPY static ./static
COPY data ./data
COPY i18n ./i18n

RUN hugo --minify --baseURL "${HUGO_BASEURL}"

FROM ${NGINX_IMAGE} AS runtime
WORKDIR /usr/share/nginx/html

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /src/public/ /usr/share/nginx/html/

EXPOSE 8080

USER 101

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
