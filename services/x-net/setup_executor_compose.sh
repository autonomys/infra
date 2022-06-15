#!/bin/bash

cat > /subspace/docker-compose.yml << EOF
version: "3.7"

services:
  node:
    image: vedhavyas/subspace-node:latest
    volumes:
      - /subspace/data/node:/var/subspace:rw
      - /subspace/data/executor:/var/executor:rw
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
        "--name", "executor-node",
        "--node-key", \$NODE_KEY,
        "--log=subspace=debug,runtime=debug,gossip::executor=trace,bundle-producer=debug,bundle-processor=debug",
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
{
  echo "        \"--\","
  echo "        \"--chain=dev\","
  echo "        \"--validator\","
  echo "        \"--base-path\", \"/var/executor\","
  echo '    ]'
} >> /subspace/docker-compose.yml
