#!/bin/bash

EXTERNAL_IP=`curl -s -4 https://ifconfig.me`

reserved_only=${1}
node_count=${2}
current_node=${3}
bootstrap_node_count=${4}
enable_domains=${5}

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
      NRIA_DISPLAY_NAME: "\${NETWORK_NAME}-bootstrap-node-evm\${NODE_ID}"
    restart: unless-stopped

  dsn-bootstrap-node:
    image: ghcr.io/\${NODE_ORG}/bootstrap-node:\${NODE_TAG}
    restart: unless-stopped
    environment:
      - RUST_LOG=info
    ports:
      - "30533:30533/tcp"
      - "30533:30533/udp"
      - "9616:9616"
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"
    command:
      - start
      - "--metrics-endpoints=0.0.0.0:9616"
      - "--keypair"
      - \${DSN_NODE_KEY}
      - "--listen-on"
      - /ip4/0.0.0.0/udp/30533/quic-v1
      - "--listen-on"
      - /ip4/0.0.0.0/tcp/30533
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
      - "--external-address"
      - "/ip4/$EXTERNAL_IP/udp/30533/quic-v1"
      - "--external-address"
      - "/ip4/$EXTERNAL_IP/tcp/30533"
EOF
for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" != "${i}" ]; then
    dsn_addr=$(sed -nr "s/NODE_${i}_SUBSPACE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
    echo "      - \"--reserved-peers\"" >> ~/subspace/docker-compose.yml
    echo "      - \"${dsn_addr}\"" >> ~/subspace/docker-compose.yml
    echo "      - \"--bootstrap-nodes\"" >> ~/subspace/docker-compose.yml
    echo "      - \"${dsn_addr}\"" >> ~/subspace/docker-compose.yml
  fi
done

cat >> ~/subspace/docker-compose.yml << EOF
  archival-node:
    image: ghcr.io/\${NODE_ORG}/node:\${NODE_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333/udp"
      - "30333:30333/tcp"
      - "30433:30433/udp"
      - "30433:30433/tcp"
      - "\${OPERATOR_PORT}:40333/tcp"
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
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/udp/30433/quic-v1",
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/tcp/30433",
#      "--piece-cache-size", "\${PIECE_CACHE_SIZE}",
      "--node-key", "\${NODE_KEY}",
      "--in-peers", "1000",
      "--out-peers", "1000",
      "--in-peers-light", "1000",
      "--dsn-in-connections", "1000",
      "--dsn-out-connections", "1000",
      "--dsn-pending-in-connections", "1000",
      "--dsn-pending-out-connections", "1000",
      "--prometheus-port", "9615",
      "--prometheus-external",
EOF


for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace//bootstrap_node_keys.txt)
    echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
    echo "      \"--bootnodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
done

if [ "${reserved_only}" == true ]; then
    echo "      \"--reserved-only\"," >> ~/subspace/docker-compose.yml
fi

if [ "${enable_domains}" == "true" ]; then
    {
    # core domain
      echo '      "--",'
      echo '      "--chain=${NETWORK_NAME}",'
      echo '      "--node-key", "${NODE_KEY}",'
    #  echo '      "--enable-subspace-block-relay",'
      echo '      "--state-pruning", "archive",'
      echo '      "--blocks-pruning", "archive",'
      echo '      "--listen-addr", "/ip4/0.0.0.0/tcp/${OPERATOR_PORT}",'
      echo '      "--domain-id=${DOMAIN_ID}",'
      echo '      "--base-path", "/var/subspace/core_${DOMAIN_LABEL}_domain",'
      echo '      "--rpc-cors", "all",'
      echo '      "--rpc-port", "8944",'
      echo '      "--unsafe-rpc-external",'
      echo '      "--relayer-id=${RELAYER_DOMAIN_ID}",'
    for (( i = 0; i <  node_count; i++ )); do
      addr=$(sed -nr "s/NODE_${i}_OPERATOR_MULTI_ADDR=//p" ~/subspace/node_keys.txt)
      echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
      echo "      \"--bootnodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
    done

    }  >> ~/subspace/docker-compose.yml
fi
echo '    ]' >> ~/subspace/docker-compose.yml
