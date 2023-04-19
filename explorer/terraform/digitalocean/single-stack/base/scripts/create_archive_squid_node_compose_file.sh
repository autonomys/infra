#!/bin/bash

cat > /archive_squid/docker-compose.yml << EOF
version: "3.7"

services:
  db:
    image: postgres:14
    restart: always
    volumes:
      # replace VOLUME_NAME with your volume name
      - /archive_squid/postgresql/data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}

  ingest:
    depends_on:
      - db
    restart: on-failure
    image: subsquid/substrate-ingest:firesquid
    command: [
      "-e", "ws://node:9944",
      "-c", "10",
       "--prom-port", "9090",
       "--out", "postgres://postgres:postgres@db:5432/archive-squid"
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
       "--database-url", "postgres://postgres:postgres@db:5432/archive-squid",
       "--database-max-connections", "3", # max number of concurrent database connections
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
    # Replace `snapshot-DATE` with latest release (like `snapshot-2022-apr-29`)
    image: ghcr.io/subspace/node:${NODE_TAG}
    volumes:
      # replace VOLUME_NAME with your volume name
      - /archive_squid/node-data:/var/subspace:rw
    restart: unless-stopped
    command: [
      # 
      "--chain", "${NETWORK_NAME}",
      "--base-path", "/var/subspace",
      "--execution", "wasm",
      "--state-pruning", "archive",
      "--rpc-cors", "all",
      "--rpc-methods", "safe",
      "--unsafe-ws-external",
      # replace NODE_NAME with your node name
      "--name", "${NODE_NAME}"
    ]
    healthcheck:
      timeout: 5s
      # If node setup takes longer then expected, you want to increase `interval` and `retries` number.
      interval: 30s
      retries: 5

  datadog:
    image: datadog/agent
    environment:
      # replace DD_API_KEY with real API key (can be genarated at https://app.datadoghq.com/organization-settings/api-keys)
      DD_API_KEY: ${DD_API_KEY}
      DD_DOGSTATSD_NON_LOCAL_TRAFFIC: "true"
      DD_LOGS_ENABLED: "true"
      DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL: "true"
      DD_CONTAINER_EXCLUDE: "name:datadog-agent"
    volumes:
     - /var/run/docker.sock:/var/run/docker.sock
     - /proc/:/host/proc/:ro
     - /sys/fs/cgroup:/host/sys/fs/cgroup:ro

  pg-health-check:
    image: ghcr.io/subspace/health-check:latest
    environment:
      POSTGRES_HOST: ${POSTGRES_HOST}
      POSTGRES_PORT: ${POSTGRES_PORT}
      PORT: ${HEALTH_CHECK_PORT}
      # provide secret, which is going to be used in 'Authorization' header
      SECRET: ${MY_SECRET}
    command: "postgres"
    ports:
      - 8080:8080
  
  prom-health-check:
    image: ghcr.io/subspace/health-check:latest
    environment:
      PROMETHEUS_HOST: ${PROCESSOR_HEALTH_HOST}
      PORT: ${PROCESSOR_HEALTH_PORT}
      # provide secret, which is going to be used in 'Authorization' header
      SECRET: ${MY_SECRET}
    command: "prometheus"
    ports:
      - 7070:7070
EOF
