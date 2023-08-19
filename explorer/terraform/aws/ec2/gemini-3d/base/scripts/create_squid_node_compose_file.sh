#!/bin/sh
source /home/$USER/.bash_profile
cat > /home/$USER/squid/docker-compose.yml << EOF
version: "3.7"

volumes:
  db_data: {}

services:
  db:
    image: postgres:14
    shm_size: 1gb
    volumes:
      - db_data:/var/lib/postgresql/data
      - type: bind
        source: /home/$USER/squid/postgresql/conf/postgresql.conf
        target: /etc/postgresql/postgresql.conf
        read_only: true
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    command: postgres -c config_file=/etc/postgresql/postgresql.conf

  run-migrations:
    image: ghcr.io/subspace/blockexplorer-processor:latest
    restart: on-failure:5
    environment:
      DB_HOST: ${DB_HOST}
      # provide DB name
      DB_NAME: ${DB_NAME}
      # provide DB password
      DB_PASS: ${DB_PASS}
    depends_on:
      - db
    command: "npm run db:migrate"

  processor:
    image: ghcr.io/subspace/blockexplorer-processor:latest
    restart: on-failure
    environment:
      # provide archive endpoint
      ARCHIVE_ENDPOINT: ${ARCHIVE_ENDPOINT}
      # provide chain RPC endpoint
      CHAIN_RPC_ENDPOINT: ${CHAIN_RPC_ENDPOINT}
      DB_HOST: ${DB_HOST}
      # provide DB name
      DB_NAME: ${DB_NAME}
      # provide DB password
      DB_PASS: ${DB_PASS}
    depends_on:
      - db
      - run-migrations
    ports:
      - "3000:3000"

  graphql:
    image: ghcr.io/subspace/blockexplorer-api-server:latest
    depends_on:
      - db
      - run-migrations
      - processor
    environment:
      DB_HOST: ${DB_HOST}
      # provide DB name
      DB_NAME: ${DB_NAME}
      # provide DB password
      DB_PASS: ${DB_PASS}
    ports:
      - "4350:4000"

  datadog:
    image: datadog/agent
    environment:
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
      SECRET: ${MY_SECRET}
    command: "postgres"
    ports:
      - 8080:8080

  prom-health-check:
    image: ghcr.io/subspace/health-check:latest
    environment:
      PROMETHEUS_HOST: ${PROCESSOR_HEALTH_HOST}
      PORT: ${PROCESSOR_HEALTH_PORT}
      SECRET: ${MY_SECRET}
    command: "prometheus"
    ports:
      - 7070:7070
EOF
