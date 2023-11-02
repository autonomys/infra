#!/bin/bash
EXTERNAL_IP=`curl -s ifconfig.me`
source /home/$USER/.bash_profile
cat > /home/$USER/archive/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}

services:
  db:
    image: postgres:16
    restart: always
    volumes:
      - /home/$USER/archive/postgresql:/var/lib/postgresql
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}

  ingest:
    depends_on:
      - db
    restart: on-failure
    image: ghcr.io/subspace/substrate-ingest:latest
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"
    command: [
      "-e", "ws://node:9944",
      "-c", "10",
       "--prom-port", "9090",
       "--out", "postgres://postgres:postgres@db:${POSTGRES_PORT}/${POSTGRES_DB}"
    ]
    environment:
      NODE_TLS_REJECT_UNAUTHORIZED: 0

  gateway:
    depends_on:
      - db
    image: subsquid/substrate-gateway:firesquid
    environment:
      RUST_LOG: "substrate_gateway=info,actix_server=info"
    command: [
       "--database-url", "postgres://postgres:postgres@db:${POSTGRES_PORT}/${POSTGRES_DB}",
       "--database-max-connections", "6", # max number of concurrent database connections
       # these parameters have to be adjusted depending on machine resources to avoid OOM
       "--scan-start-value", "20", # works as batch size but for a whole archive, default is 100
       "--scan-max-value", "20000" # upper limit for the amount of blocks, default is 100000
    ]
    ports:
      - "8888:8000"

  # Explorer service is optional.
  # It provides rich GraphQL API for querying archived data.
  # Many developers find it very useful for exploration and debugging.
  explorer:
    image: subsquid/substrate-explorer:firesquid
    environment:
      DB_TYPE: ${DB_TYPE}
      DB_HOST: ${DB_HOST}
      DB_PORT: ${DB_PORT}
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASS: ${DB_PASS}
    ports:
      - "4444:3000"

  node:
    image: ghcr.io/subspace/node:${NODE_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    command: [
      "--chain", "${NETWORK_NAME}",
      "--base-path", "/var/subspace",
      "--execution", "wasm",
      "--state-pruning", "archive",
      "--blocks-pruning", "archive",
      "--listen-addr", "/ip4/0.0.0.0/tcp/30333",
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/tcp/30433",
      "--rpc-cors", "all",
      "--rpc-methods", "unsafe",
      "--rpc-external",
      "--no-private-ipv4",
      "--name", "${NODE_NAME}"
    ]
    healthcheck:
      timeout: 5s
      interval: 30s
      retries: 5

  agent:
    container_name: newrelic-infra
    image: newrelic/infrastructure:latest
    cap_add:
      - SYS_PTRACE
    network_mode: bridge
    pid: host
    privileged: true
    volumes:
      - "/:/host:ro"
      - "/var/run/docker.sock:/var/run/docker.sock"
    environment:
      NRIA_LICENSE_KEY: "${NR_API_KEY}"
      NRIA_DISPLAY_NAME: "archive-squid-gemini-3g"
    restart: unless-stopped

  pg-health-check:
    image: ghcr.io/subspace/health-check:latest
    environment:
      POSTGRES_HOST: ${POSTGRES_HOST}
      POSTGRES_PORT: ${POSTGRES_PORT}
      PORT: ${HEALTH_CHECK_PORT}
      SECRET: ${MY_SECRET}
    command: "postgres"
    ports:
      - 8080:8080

  prom-health-check:
    image: ghcr.io/subspace/health-check:latest
    environment:
      PROMETHEUS_HOST: ${INGEST_HEALTH_HOST}
      PORT: ${INGEST_HEALTH_PORT}
      SECRET: ${MY_SECRET}
    command: "prometheus"
    ports:
      - 7070:7070
EOF
