#!/bin/bash

cat > /subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  farmer_data: {}
  node_data: {}

services:
  farmer:
    depends_on:
      node:
        condition: service_healthy
    image: vedhavyas/subspace-farmer:latest
    volumes:
      - farmer_data:/var/subspace:rw
    restart: unless-stopped
    command: [
      "--base-path", "/var/subspace",
      "farm",
      "--node-rpc-url", "ws://node:9944",
      "--ws-server-listen-addr", "0.0.0.0:9955",
      "--reward-address", \$WALLET_ADDRESS,
      "--plot-size", "100G"
    ]
  node:
    image: vedhavyas/subspace-node:latest
    volumes:
      - node_data:/var/subspace:rw
    ports:
      - "30333:30333"
    restart: unless-stopped
    command: [
        "--chain", "x-net-1",
        "--base-path", "/var/subspace",
        "--execution", "wasm",
        "--pruning", "1024",
        "--keep-blocks", "1024",
        "--port", "30333",
        "--rpc-cors", "all",
        "--rpc-methods", "safe",
        "--unsafe-ws-external",
        "--force-authoring",
        "--validator",
        "--name", "farmer-node",
        "--node-key", \$NODE_KEY,
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
echo '    healthcheck:
            timeout: 5s
            interval: 30s
            retries: 5' >> /subspace/docker-compose.yml
