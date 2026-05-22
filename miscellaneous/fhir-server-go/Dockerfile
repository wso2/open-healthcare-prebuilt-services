FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o fhir-server ./cmd/server

FROM scratch
COPY --from=builder /app/fhir-server /fhir-server
EXPOSE 9090
ENTRYPOINT ["/fhir-server"]
