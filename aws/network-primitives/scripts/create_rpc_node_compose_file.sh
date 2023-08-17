#!/bin/bash

EXTERNAL_IP=`curl -s ifconfig.me`

cat > ~/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  caddy_data: {}
  archival_node_data: {}

services:
  datadog:
    container_name: "datadog_agent"
    image: gcr.io/datadoghq/agent:7
    restart: unless-stopped
    environment:
      - DD_API_KEY=\${DATADOG_API_KEY}
      - DD_SITE=datadoghq.com
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /proc/:/host/proc/:ro
      - /sys/fs/cgroup/:/host/sys/fs/cgroup:ro
      - /etc/os-release:/host/etc/os-release:ro

  # caddy reverse proxy with automatic tls management using let encrypt
  caddy:
    image: lucaslorentz/caddy-docker-proxy:latest
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - CADDY_INGRESS_NETWORKS=subspace_default
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - caddy_data:/data

  archival-node:
    image: ghcr.io/\${NODE_ORG}/node:\${NODE_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    labels:
      caddy_0: \${DOMAIN_PREFIX}-\${NODE_ID}.\${NETWORK_NAME}.subspace.network
      caddy_0.handle_path_0: /ws
      caddy_0.handle_path_0.reverse_proxy: "{{upstreams 9944}}"
    command: [
      "--chain", "\${NETWORK_NAME}",
      "--base-path", "/var/subspace",
      "--execution", "wasm",
#      "--enable-subspace-block-relay",
      "--state-pruning", "archive",
      "--blocks-pruning", "archive",
      "--listen-addr", "/ip4/0.0.0.0/tcp/30333",
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/tcp/30433",
#      "--piece-cache-size", "\${PIECE_CACHE_SIZE}",
      "--node-key", "\${NODE_KEY}",
      "--rpc-cors", "all",
      "--rpc-external",
      "--in-peers", "500",
      "--out-peers", "250",
      "--in-peers-light", "500",
      "--rpc-max-connections", "10000",
EOF

reserved_only=${1}
node_count=${2}
current_node=${3}
bootstrap_node_count=${4}
dsn_bootstrap_node_count=${4}

for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" != "${i}" ]; then
    addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace//bootstrap_node_keys.txt)
    echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
    echo "      \"--bootnodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
  fi
done

for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace//bootstrap_node_keys.txt)
  echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
  echo "      \"--bootnodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
done

# // TODO: make configurable with gemini network as it's not needed for devnet
# for (( i = 0; i < dsn_bootstrap_node_count; i++ )); do
#   dsn_addr=$(sed -nr "s/NODE_${i}_SUBSPACE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
#   echo "      \"--dsn-reserved-peers\", \"${dsn)addr}\"," >> ~/subspace/docker-compose.yml
#   echo "      \"--dsn-bootstrap-nodes\", \"${dsn_addr}\"," >> ~/subspace/docker-compose.yml
# done

if [ "${reserved_only}" == true ]; then
    echo "      \"--reserved-only\"," >> ~/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/docker-compose.yml
