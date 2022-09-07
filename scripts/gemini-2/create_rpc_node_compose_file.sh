#!/bin/bash

cat > /subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  caddy_data: {}
  archival_node_data: {}

services:
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
    image: ghcr.io/nazar-pc/node:\${NODE_SNAPSHOT_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333"
    labels:
      caddy: eu-\${NODE_ID}.gemini-2a.subspace.network
      caddy.handle_path_0: /http
      caddy.handle_path_0.reverse_proxy: "{{upstreams 9933}}"
      caddy.handle_path_1: /ws
      caddy.handle_path_1.reverse_proxy: "{{upstreams 9944}}"
    command: [
      "--chain", "gemini-2a",
      "--base-path", "/var/subspace",
      "--execution", "wasm",
      "--state-pruning", "archive",
      "--listen-addr", "/ip4/0.0.0.0/tcp/30333",
      "--node-key", \$NODE_KEY,
      "--rpc-cors", "all",
      "--reserved-only",
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

bootstrap_node_count=${3}
for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" /subspace/bootstrap_node_keys.txt)
  echo "      \"--reserved-nodes\", \"${addr}\"," >> /subspace/docker-compose.yml
  echo "      \"--bootnodes\", \"${addr}\"," >> /subspace/docker-compose.yml
done

echo '    ]' >> /subspace/docker-compose.yml
