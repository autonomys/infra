#!/bin/bash

EXTERNAL_IP=`curl -s -4 https://ifconfig.me`
EXTERNAL_IP_V6=`curl -s -6 https://ifconfig.me`

reserved_only=${1}
node_count=${2}
current_node=${3}

cat > ~/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}
  vmagentdata: {}

services:
  vmagent:
    container_name: vmagent
    image: victoriametrics/vmagent:latest
    depends_on:
      - "archival-node"
    ports:
      - 8429:8429
    volumes:
      - vmagentdata:/vmagentdata
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    command:
      - "--httpListenAddr=0.0.0.0:8429"
      - "--promscrape.config=/etc/prometheus/prometheus.yml"
      - "--remoteWrite.url=http://vmetrics.subspace.network:8428/api/v1/write"

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
      NRIA_DISPLAY_NAME: "\${NETWORK_NAME}-bootstrap-node-\${NODE_ID}"
    restart: unless-stopped

  dsn-bootstrap-node:
    image: ghcr.io/\${NODE_ORG}/bootstrap-node:\${DOCKER_TAG}
    restart: unless-stopped
    environment:
      - RUST_LOG=info
    ports:
      - "30533:30533/tcp"
      - "9616:9616"
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"
    command:
      - start
      - "--prometheus-listen-on=0.0.0.0:9616"
      - "--keypair"
      - \${DSN_NODE_KEY}
      - "--listen-on"
      - /ip4/0.0.0.0/tcp/30533
      - "--listen-on"
      - /ip6/::/tcp/30533
      - --protocol-version
      - \${GENESIS_HASH}
      - "--in-peers"
      - "1000"
      - "--out-peers"
      - "1000"
      - "--pending-in-peers"
      - "1000"
      - "--pending-out-peers"
      - "1000"
EOF

for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" == "${i}" ]; then
    dsn_addr=$(sed -nr "s/NODE_${i}_SUBSPACE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
    echo "      - \"--external-address\"" >> ~/subspace/docker-compose.yml
    echo "      - \"${dsn_addr}\"" >> ~/subspace/docker-compose.yml
  fi
done

for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" != "${i}" ]; then
    dsn_addr=$(sed -nr "s/NODE_${i}_SUBSPACE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
    echo "      - \"--reserved-peer\"" >> ~/subspace/docker-compose.yml
    echo "      - \"${dsn_addr}\"" >> ~/subspace/docker-compose.yml
    echo "      - \"--bootstrap-node\"" >> ~/subspace/docker-compose.yml
    echo "      - \"${dsn_addr}\"" >> ~/subspace/docker-compose.yml
  fi
done

cat >> ~/subspace/docker-compose.yml << EOF
  archival-node:
    image: ghcr.io/\${NODE_ORG}/node:\${DOCKER_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333/tcp"
      - "30433:30433/tcp"
      - "9615:9615"
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"
    command: [
      "run",
      "--chain", "\${NETWORK_NAME}",
      "--base-path", "/var/subspace",
      "--state-pruning", "archive",
      "--blocks-pruning", "256",
      "--pot-external-entropy", "\${POT_EXTERNAL_ENTROPY}",
      "--listen-on", "/ip4/0.0.0.0/tcp/30333",
      "--listen-on", "/ip6/::/tcp/30333",
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/tcp/30433",
      "--dsn-external-address", "/ip6/$EXTERNAL_IP_V6/tcp/30433",
      "--node-key", "\${NODE_KEY}",
      "--in-peers", "2000",
      "--out-peers", "2000",
      "--dsn-in-connections", "2000",
      "--dsn-out-connections", "2000",
      "--dsn-pending-in-connections", "2000",
      "--dsn-pending-out-connections", "2000",
      "--prometheus-listen-on", "0.0.0.0:9615",
EOF

for (( i = 0; i < node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/node_keys.txt)
  echo "      \"--reserved-peer\", \"${addr}\"," >> ~/subspace/docker-compose.yml
  echo "      \"--bootstrap-node\", \"${addr}\"," >> ~/subspace/docker-compose.yml
done

if [ "${reserved_only}" == true ]; then
    echo "      \"--reserved-only\"," >> ~/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/docker-compose.yml
