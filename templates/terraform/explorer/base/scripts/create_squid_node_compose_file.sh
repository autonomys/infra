#!/bin/sh
source $HOME/.bash_profile
cat > $HOME/squid/docker-compose.yml << EOF
version: "3.7"

volumes:
  db_data: {}

services:
  db:
    image: postgres:16
    shm_size: 1gb
    volumes:
      - db_data:/var/lib/postgresql/data
      - type: bind
        source: $HOME/squid/postgresql/conf/postgresql.conf
        target: /etc/postgresql/postgresql.conf
        read_only: true
    environment:
      POSTGRES_DB: squid-archive
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
    expose:
      - "5432"
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"

  db_replica:
    image: postgres:16
    shm_size: 1gb
    volumes:
      - db_data_replica:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: squid-archive
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    command: >
      bash -c "until pg_isready -h db_primary -p 5432 -U ${POSTGRES_USER}; do sleep 1; done;
      pg_basebackup -h db_primary -D /var/lib/postgresql/data -U ${POSTGRES_USER} -P -v --wal-method=stream;
      echo 'hot_standby = on' >> /var/lib/postgresql/data/postgresql.conf;
      echo 'primary_conninfo = ''host=db_primary port=5432 user=${POSTGRES_USER} password=${POSTGRES_PASSWORD}''' >> /var/lib/postgresql/data/postgresql.conf;
      pg_ctl -D /var/lib/postgresql/data -o '-c config_file=/var/lib/postgresql/data/postgresql.conf' start"
    depends_on:
      - db_primary

  pgcat:
    image: ghcr.io/postgresml/pgcat:e1e4929d439313d987c352b4517a6d99627f3e9c
    command:
      - "pgcat"
      - "/etc/pgcat/pgcat.toml"
    volumes:
      - "$HOME/squid/postgresql/conf/pgcat.toml:/etc/pgcat/pgcat.toml"
    ports:
      - "6432:6432"
      - "9930:9930"

  run-migrations:
    image: ghcr.io/subspace/blockexplorer-processor:\${DOCKER_TAG}
    restart: on-failure:5
    environment:
      DB_HOST: \${DB_HOST}
      # provide DB name
      DB_NAME: \${DB_NAME}
      # provide DB password
      DB_PASS: \${DB_PASS}
      # provide DB port
      DB_PORT: \${DB_PORT}
    depends_on:
      - db
    command: "npm run db:migrate"

  processor:
    image: ghcr.io/subspace/blockexplorer-processor:\${DOCKER_TAG}
    restart: on-failure
    environment:
      # provide archive endpoint
      ARCHIVE_ENDPOINT: \${ARCHIVE_ENDPOINT}
      # provide chain RPC endpoint
      CHAIN_RPC_ENDPOINT: \${CHAIN_RPC_ENDPOINT}
      DB_HOST: \${DB_HOST}
      # provide DB name
      DB_NAME: \${DB_NAME}
      # provide DB password
      DB_PASS: \${DB_PASS}
      # provide DB port
      DB_PORT: \${DB_PORT}
    depends_on:
      - db
      - run-migrations
    ports:
      - "3000:3000"
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"

  graphql:
    image: ghcr.io/subspace/blockexplorer-api-server:\${DOCKER_TAG}
    depends_on:
      - db
      - run-migrations
      - processor
    environment:
      DB_HOST: \${DB_HOST}
      # provide DB name
      DB_NAME: \${DB_NAME}
      # provide DB password
      DB_PASS: \${DB_PASS}
      # provide DB port
      DB_PORT: \${DB_PORT}
    ports:
      - "4350:4000"
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"

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
      NRIA_LICENSE_KEY: "\${NR_API_KEY}"
      NRIA_DISPLAY_NAME: "squid-\${NETWORK_NAME}"
    restart: unless-stopped

  pg-health-check:
    image: ghcr.io/subspace/health-check:latest
    environment:
      POSTGRES_HOST: \${POSTGRES_HOST}
      POSTGRES_PORT: \${POSTGRES_PORT}
      PORT: \${HEALTH_CHECK_PORT}
      SECRET: \${MY_SECRET}
    command: "postgres"
    ports:
      - 8080:8080

  prom-health-check:
    image: ghcr.io/subspace/health-check:latest
    environment:
      PROMETHEUS_HOST: \${PROCESSOR_HEALTH_HOST}
      PORT: \${PROCESSOR_HEALTH_PORT}
      SECRET: \${MY_SECRET}
    command: "prometheus"
    ports:
      - 7070:7070
EOF
