# --- Stage 1: Build ---
FROM docker.io/library/rust:slim-trixie AS builder
WORKDIR /usr/src/app
COPY . .
RUN cargo build --release

# --- Stage 2: Runtime ---
FROM docker.io/library/debian:trixie-slim AS runtime
ARG APP_NAME=rust-app
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /usr/app
COPY --from=builder /usr/src/app/target/release/${APP_NAME} ./app-binary
CMD ["./app-binary"]
