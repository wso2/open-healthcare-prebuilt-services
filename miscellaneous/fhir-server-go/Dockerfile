FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o fhir-server ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/fhir-server /fhir-server
EXPOSE 9090
USER nonroot:nonroot
ENTRYPOINT ["/fhir-server"]
