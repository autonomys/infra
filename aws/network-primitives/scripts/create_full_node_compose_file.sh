#!/bin/bash

EXTERNAL_IP=`curl -s -4 https://ifconfig.me`

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
      - "--promscrape.config=/etc/prometheus/prometheus.yml"
      - "--remoteWrite.url=https://vmetrics.subspace.network:8428/api/v1/write"

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
      NRIA_LICENSE_KEY: ${NR_API_KEY}
      NRIA_DISPLAY_NAME: "full-node-${NODE_ID}"
    restart: unless-stopped

  archival-node:
    image: ghcr.io/\${NODE_ORG}/node:\${NODE_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333"
      - "30433:30433"
      - "9615:9615"
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"
    command: [
      "--chain", "\${NETWORK_NAME}",
      "--base-path", "/var/subspace",
      "--execution", "wasm",
#      "--enable-subspace-block-relay",
      "--state-pruning", "archive",
      "--blocks-pruning", "256",
      "--listen-addr", "/ip4/0.0.0.0/tcp/30333",
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/tcp/30433",
#      "--piece-cache-size", "\${PIECE_CACHE_SIZE}",
      "--node-key", "\${NODE_KEY}",
      "--in-peers", "1000",
      "--out-peers", "1000",
      "--dsn-in-connections", "1000",
      "--dsn-out-connections", "1000",
      "--dsn-pending-in-connections", "1000",
      "--dsn-pending-out-connections", "1000",
      "--in-peers-light", "500",
      "--rpc-max-connections", "10000",
      "--prometheus-port", "9615",
      "--prometheus-external",
EOF

reserved_only=${1}
node_count=${2}
current_node=${3}
bootstrap_node_count=${4}
dsn_bootstrap_node_count=${4}

for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace//bootstrap_node_keys.txt)
  echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
  echo "      \"--bootnodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
done

# // TODO: make configurable with gemini network as it's not needed for devnet
for (( i = 0; i < dsn_bootstrap_node_count; i++ )); do
  dsn_addr=$(sed -nr "s/NODE_${i}_SUBSPACE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
  echo "      \"--dsn-reserved-peers\", \"${dsn)addr}\"," >> ~/subspace/docker-compose.yml
  echo "      \"--dsn-bootstrap-nodes\", \"${dsn_addr}\"," >> ~/subspace/docker-compose.yml
done

if [ "${reserved_only}" == true ]; then
    echo "      \"--reserved-only\"," >> ~/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/docker-compose.yml
