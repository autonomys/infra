#!/bin/bash

EXTERNAL_IP=`curl -s -4 https://ifconfig.me`

reserved_only=${1}
node_count=${2}
current_node=${3}

cat > ~/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}

services:
  dsn-bootstrap-node:
    build:
      context: .
      dockerfile: $HOME/subspace/subspace/Dockerfile-bootstrap-node
    image: \${NODE_ORG}/node:\${NODE_TAG}
    restart: unless-stopped
    environment:
      - RUST_LOG=info
    ports:
      - "30533:30533"
    command:
      - start
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
    build:
      context: .
      dockerfile: $HOME/subspace/subspace/Dockerfile-node
    image: \${NODE_ORG}/node:\${NODE_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333/udp"
      - "30433:30433/udp"
      - "30333:30333/tcp"
      - "30433:30433/tcp"
      - "9615:9615"
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

for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" != "${i}" ]; then
    addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/node_keys.txt)
    echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
    echo "      \"--bootnodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
  fi
done

if [ "${reserved_only}" == true ]; then
    echo "      \"--reserved-only\"," >> ~/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/docker-compose.yml
