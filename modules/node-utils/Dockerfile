FROM rust:bullseye AS builder

RUN apt-get update && apt-get install -y libssl-dev pkg-config

RUN mkdir -p /node-utils
WORKDIR /node-utils
COPY src src
COPY Cargo.lock Cargo.lock
COPY Cargo.toml Cargo.toml
COPY rustfmt.toml rustfmt.toml
COPY rust-toolchain.toml rust-toolchain.toml
RUN cargo build --release

FROM debian:bullseye

RUN apt-get update && apt-get install -y libssl-dev ca-certificates && update-ca-certificates

WORKDIR /
COPY --from=builder /node-utils/target/release/node-utils /node-utils
ENV RUST_LOG=info

ENTRYPOINT ["/node-utils"]