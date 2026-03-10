FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o demo-app .

FROM gcr.io/distroless/static-debian12

COPY --from=builder /app/demo-app /demo-app

USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/demo-app"]
