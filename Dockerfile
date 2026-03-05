FROM docker.io/library/golang:1.24.6-bullseye@sha256:2cdc80dc25edcb96ada1654f73092f2928045d037581fa4aa7c40d18af7dd85a AS gobuild
WORKDIR /build-dir
COPY go.mod .
COPY go.sum .
RUN go mod download
COPY internal internal
COPY cmd cmd
COPY pkg pkg
RUN mkdir -p /tmp/openapi
COPY api/openapi.json /tmp/openapi/openapi.json
COPY api/openapi.yml /tmp/openapi/openapi.yml

RUN apt-get update && \
    apt-get install -y libsecp256k1-0 libsodium23
RUN go build -o /tmp/opentonapi github.com/tonkeeper/opentonapi/cmd/api

FROM ubuntu:24.04@sha256:d1e2e92c075e5ca139d51a140fff46f84315c0fdce203eab2807c7e495eff4f9 as runner
RUN apt-get update && \
    apt-get install -y openssl ca-certificates libsecp256k1-0 libsodium23 wget && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /app/lib
COPY --from=gobuild /go/pkg/mod/github.com/tonkeeper/tongo*/lib/linux /app/lib/
ENV LD_LIBRARY_PATH=/app/lib/
COPY --from=gobuild /tmp/opentonapi /usr/bin/
COPY --from=gobuild /tmp/openapi /app/openapi
WORKDIR /app
CMD ["/usr/bin/opentonapi"]
