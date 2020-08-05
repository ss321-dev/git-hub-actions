FROM golang:1.14.4-alpine3.12 AS build-env
RUN apk --no-cache add gcc musl-dev git
ADD . ./
WORKDIR ./
RUN go build -a -installsuffix cgo -ldflags "-s -w" -o /app

FROM alpine:3.12
ENV GOPATH=/go
RUN apk add --no-cache ca-certificates curl
COPY --from=build-env /app /app
ENTRYPOINT ["/app", "--host", "0.0.0.0", "--port", "80", "--scheme", "http"]
