#!/bin/bash

cat > ~/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}
  farmer_data: {}

services:
  datadog:
    container_name: "datadog_agent"
    image: gcr.io/datadoghq/agent:7
    restart: unless-stopped
    environment:
      - DD_API_KEY=\$DATADOG_API_KEY
      - DD_SITE=datadoghq.com
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
      - /etc/os-release:/host/etc/os-release:ro

  farmer:
    depends_on:
      archival-node:
        condition: service_healthy
    image: ghcr.io/\$NODE_ORG/farmer:\$NODE_TAG
    volumes:
      - farmer_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30533:30533"
    command: [
      "--base-path", "/var/subspace",
      "farm",
      "--node-rpc-url", "ws://archival-node:9944",
      "--listen-on", "/ip4/0.0.0.0/tcp/30533",
      "--reward-address", \$REWARD_ADDRESS,
      "--plot-size", \$PLOT_SIZE,
    ]

  archival-node:
    image: ghcr.io/\$NODE_ORG/node:\$NODE_TAG
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333"
      - "\${NODE_DSN_PORT}:30433"
    command: [
      "--chain", \$NETWORK_NAME,
      "--base-path", "/var/subspace",
      "--execution", "wasm",
      "--state-pruning", "archive",
      "--blocks-pruning", "archive",
      "--listen-addr", "/ip4/0.0.0.0/tcp/30333",
      "--dsn-disable-private-ips",
      "--piece-cache-size", \$PIECE_CACHE_SIZE,
      "--no-private-ipv4",
      "--node-key", \$NODE_KEY,
      "--validator",
      "--rpc-cors", "all",
      "--ws-port", "9944",
      "--unsafe-ws-external",
EOF

reserved_only=${1}
node_count=${2}
current_node=${3}
bootstrap_node_count=${4}
dsn_bootstrap_node_count=${4}
force_block_production=${5}

for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" != "${i}" ]; then
    addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/node_keys.txt)
    echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
    echo "      \"--bootnodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
  fi
done


for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/bootstrap_node_keys.txt)
  echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
  echo "      \"--bootnodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
done

for (( i = 0; i < dsn_bootstrap_node_count; i++ )); do
  dsn_addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
  echo "      \"--dsn-bootstrap-nodes\", \"${dsn_addr}\"," >> ~/subspace/docker-compose.yml
done

if [ "${reserved_only}" == true ]; then
  echo "      \"--reserved-only\"," >> ~/subspace/docker-compose.yml
fi

if [ "${force_block_production}" == true ]; then
  echo "      \"--force-synced\"," >> ~/subspace/docker-compose.yml
  echo "      \"--force-authoring\"," >> ~/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/docker-compose.yml
