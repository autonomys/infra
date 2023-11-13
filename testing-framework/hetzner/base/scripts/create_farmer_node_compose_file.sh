#!/bin/bash

EXTERNAL_IP=`curl -s -4 https://ifconfig.me`

cat > ~/subspace/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}
  farmer_data: {}

services:
  farmer:
    depends_on:
      archival-node:
        condition: service_healthy
    build:
      context: .
      dockerfile: $HOME/subspace/subspace/Dockerfile-farmer
    image: \${NODE_ORG}/\${NODE_TAG}:latest
    volumes:
      - farmer_data:/var/subspace
    restart: unless-stopped
    ports:
      - "30533:30533"
    command: [
      "farm", "path=/var/subspace,size=\${PLOT_SIZE}",
      "--node-rpc-url", "ws://archival-node:9944",
      "--external-address", "/ip4/$EXTERNAL_IP/tcp/30533",
      "--listen-on", "/ip4/0.0.0.0/tcp/30533",
      "--reward-address", "\${REWARD_ADDRESS}",
    ]

  archival-node:
    build:
      context: $HOME/subspace/subspace/
      dockerfile: Dockerfile-node
    image: \${NODE_ORG}/node:\${NODE_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333"
      - "30433:30433"
      - "9615:9615"
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
      "--validator",
      "--timekeeper",
      "--rpc-cors", "all",
      "--rpc-external",
      "--rpc-methods", "unsafe",
      "--prometheus-port", "9615",
      "--prometheus-external",
EOF

reserved_only=${1}
node_count=${2}
current_node=${3}
bootstrap_node_count=${4}
dsn_bootstrap_node_count=${4}
force_block_production=${5}

for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace//bootstrap_node_keys.txt)
  echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--bootnodes\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

# // TODO: make configurable with gemini network
for (( i = 0; i < dsn_bootstrap_node_count; i++ )); do
  dsn_addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
  echo "      \"--dsn-reserved-peers\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--dsn-bootstrap-nodes\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

if [ "${reserved_only}" == true ]; then
  echo "      \"--reserved-only\"," >> ~/subspace/subspace/docker-compose.yml
fi

if [ "${force_block_production}" == true ]; then
  echo "      \"--force-synced\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--force-authoring\"," >> ~/subspace/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/subspace/docker-compose.yml
