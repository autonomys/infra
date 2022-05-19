#!/bin/bash

cat > /subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  caddy_data: {}
  archival_node_data: {}

services:
  # caddy reverse proxy with automatic tls management using let encrypt
  caddy:
    container_name: caddy
    image: lucaslorentz/caddy-docker-proxy:latest
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      - CADDY_INGRESS_NETWORKS=gemini-1_default
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - caddy_data:/data

  archival-node:
    container_name: archival-node
    image: ghcr.io/subspace/node:\${NODE_SNAPSHOT_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333"
    labels:
      caddy: rpc-\${NODE_ID}.gemini-1.subspace.network bootstrap-\${NODE_ID}.gemini-1.subspace.network
      caddy.handle_path_0: /rpc/*
      caddy.handle_path_0.reverse_proxy: "{{upstreams 9933}}"
      caddy.handle_path_1: /ws/*
      caddy.handle_path_1.reverse_proxy: "{{upstreams 9944}}"
    command: [
      # TODO: change the chain
      "--chain", "local",
      "--base-path", "/var/subspace",
      "--wasm-execution", "compiled",
      "--execution", "wasm",
      "--pruning", "archive",
      "--pool-kbytes", "51200",
      "--node-key", \$NODE_KEY,
      "--telemetry-url", "wss://telemetry.polkadot.io/submit/ 1",
      "--reserved-only",
      "--rpc-cors", "all",
      "--rpc-external",
      "--ws-external",
      "--ws-max-connections", "1000",
EOF

node_count=${1}
for (( i = 0; i < node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" /subspace/node_keys.txt)
  echo "      \"--reserved-nodes\", \"${addr}\"," >> /subspace/docker-compose.yml
done

echo '    ]' >> /subspace/docker-compose.yml
