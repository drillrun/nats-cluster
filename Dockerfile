ARG PROMETHEUS_NATS_EXPORTER="https://github.com/nats-io/prometheus-nats-exporter/releases/download/v0.16.0/prometheus-nats-exporter-v0.16.0-linux-x86_64.tar.gz"

### stage: get nats exporter
FROM curlimages/curl:latest AS metrics

WORKDIR /metrics/
ARG PROMETHEUS_NATS_EXPORTER
USER root
RUN mkdir -p /metrics/
RUN curl -o nats-exporter.tar.gz     \
     -L $PROMETHEUS_NATS_EXPORTER && \
     tar vxf nats-exporter.tar.gz

### stage: build flyutil
FROM golang:1.17 AS flyutil
ARG VERSION

WORKDIR /go/src/github.com/fly-apps/nats-cluster
COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -v -o /fly/bin/start ./cmd/start

# stage: final image
FROM nats:2.11-scratch AS nats-server

FROM gcr.io/distroless/cc-debian12:debug
COPY --from=nats-server /nats-server /usr/local/bin/
COPY --from=metrics /metrics/prometheus-nats-exporter /usr/local/bin/nats-exporter
COPY --from=flyutil /fly/bin/start /usr/local/bin/

CMD ["start"]