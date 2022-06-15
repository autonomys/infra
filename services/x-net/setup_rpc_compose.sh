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
    image: vedhavyas/subspace-node:latest
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333"
    labels:
      caddy: rpc.x-net.subspace.network
      caddy.handle_path_0: /http
      caddy.handle_path_0.reverse_proxy: "{{upstreams 9933}}"
      caddy.handle_path_1: /ws
      caddy.handle_path_1.reverse_proxy: "{{upstreams 9944}}"
    command: [
      "--chain", "x-net-1",
      "--base-path", "/var/subspace",
      "--execution", "wasm",
      "--pruning", "archive",
      "--pool-kbytes", "51200",
      "--listen-addr", "/ip4/0.0.0.0/tcp/30333",
      "--name", "rpc-node",
      "--node-key", \$NODE_KEY,
      "--rpc-cors", "all",
      "--rpc-external",
      "--ws-external",
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
