#!/bin/bash

cat > /subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}

services:
  archival-node:
    image: ghcr.io/subspace/node:\${NODE_SNAPSHOT_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333"
    command: [
      "--chain", "gemini-1",
      "--base-path", "/var/subspace",
      "--execution", "wasm",
      "--state-pruning", "archive-canonical"
      "--listen-addr", "/ip4/0.0.0.0/tcp/30333",
      "--node-key", \$NODE_KEY,
      "--rpc-cors", "all",
      "--rpc-external",
      "--ws-external",
      "--in-peers", "500",
      "--out-peers", "250",
      "--in-peers-light", "500",
      "--ws-max-connections", "10000",
EOF

node_count=${1}
current_node=${2}
for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" != "${i}" ]; then
    addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" /subspace/node_keys.txt)
    echo "      \"--reserved-nodes\", \"${addr}\"," >> /subspace/docker-compose.yml
    echo "      \"--bootnodes\", \"${addr}\"," >> /subspace/docker-compose.yml
  fi
done

echo '    ]' >> /subspace/docker-compose.yml
