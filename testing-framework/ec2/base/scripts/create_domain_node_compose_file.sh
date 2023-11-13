#!/bin/bash

EXTERNAL_IP=`curl -s -4 https://ifconfig.me`

cat > ~/subspace/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}

services:
  archival-node:
    build:
      context: .
      dockerfile: $HOME/subspace/subspace/Dockerfile-node
    image: \${NODE_ORG}/\${NODE_TAG}:latest
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333/udp"
      - "30433:30433/udp"
      - "30333:30333/tcp"
      - "30433:30433/tcp"
      - "40333:40333"
      - "9615:9615"
    command: [
      "--chain", "\${NETWORK_NAME}",
      "--base-path", "/var/subspace",
      "--execution", "wasm",
#      "--enable-subspace-block-relay",
      "--state-pruning", "archive",
      "--blocks-pruning", "archive",
      "--listen-addr", "/ip4/0.0.0.0/tcp/30333",
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/udp/30433/quic-v1",
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/tcp/30433",
#      "--piece-cache-size", "\${PIECE_CACHE_SIZE}",
      "--node-key", "\${NODE_KEY}",
      "--rpc-cors", "all",
      "--rpc-external",
      "--in-peers", "500",
      "--out-peers", "250",
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
enable_domains=${5}
domain_id=${6}

for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace//bootstrap_node_keys.txt)
  echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--bootnodes\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

#// TODO: make configurable with gemini network as it's not needed for devnet
for (( i = 0; i < dsn_bootstrap_node_count; i++ )); do
  dsn_addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
  echo "      \"--dsn-reserved-peers\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--dsn-bootstrap-nodes\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

if [ "${reserved_only}" == "true" ]; then
    echo "      \"--reserved-only\"," >> ~/subspace/subspace/docker-compose.yml
fi

if [ "${enable_domains}" == "true" ]; then
    {
    # core domain
      echo '      "--",'
      echo '      "--chain=${NETWORK_NAME}",'
    #  echo '      "--enable-subspace-block-relay",'
      echo '      "--state-pruning", "archive",'
      echo '      "--blocks-pruning", "archive",'
      echo '      "--domain-id=${DOMAIN_ID}",'
      echo '      "--base-path", "/var/subspace/core_${DOMAIN_LABEL}_domain",'
      echo '      "--listen-addr", "/ip4/0.0.0.0/tcp/40333",'
      echo '      "--rpc-cors", "all",'
      echo '      "--rpc-port", "8944",'
      echo '      "--unsafe-rpc-external",'
      echo '      "--relayer-id=${RELAYER_DOMAIN_ID}",'

    }  >> ~/subspace/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/subspace/docker-compose.yml
