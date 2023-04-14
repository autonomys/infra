#!/bin/bash

cat > /subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}

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

  dsn-bootstrap-node:
    image: ghcr.io/\${NODE_ORG}/bootstrap-node:\${NODE_TAG}
    restart: unless-stopped
    environment:
      - RUST_LOG=info
    ports:
      - "50001:50001"
    command: [
      "start",
       \$DSN_NODE_KEY, "/ip4/0.0.0.0/tcp/50001",
        "--protocol-version", \$GENESIS_HASH
      ]

  archival-node:
    image: ghcr.io/\${NODE_ORG}/node:\${NODE_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333"
      - "30434:30433"
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
      "--in-peers", "1000",
      "--out-peers", "1000",
      "--dsn-in-connections", "1000",
      "--dsn-out-connections", "1000",
      "--dsn-pending-in-connections", "1000",
      "--dsn-pending-out-connections", "1000",
      "--in-peers-light", "1000",
      "--ws-max-connections", "10000",
EOF

reserved_only=${1}
node_count=${2}
current_node=${3}
for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" != "${i}" ]; then
    addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" /subspace/node_keys.txt)
    echo "      \"--reserved-nodes\", \"${addr}\"," >> /subspace/docker-compose.yml
    echo "      \"--bootnodes\", \"${addr}\"," >> /subspace/docker-compose.yml
    addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" /subspace/dsn_bootstrap_node_keys.txt)
    echo "      \"--dsn-bootstrap-nodes\", \"${addr}\"," >> /subspace/docker-compose.yml
  fi
done

if [ "${reserved_only}" == "true" ]; then
    echo "      \"--reserved-only\"," >> /subspace/docker-compose.yml
fi

echo '    ]' >> /subspace/docker-compose.yml
