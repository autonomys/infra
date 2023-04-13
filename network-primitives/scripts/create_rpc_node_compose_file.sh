#!/bin/bash

cat > /subspace/docker-compose.yml << EOF
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
      - DD_API_KEY=\$DATADOG_API_KEY
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
    ports:
      - "30333:30333"
      - "30434:30434"
    labels:
      caddy_0: \${DOMAIN_PREFIX}-\${NODE_ID}.\${NETWORK_NAME}.subspace.network
      caddy_0.handle_path_0: /http
      caddy_0.handle_path_0.reverse_proxy: "{{upstreams 9933}}"
      caddy_0.handle_path_1: /ws
      caddy_0.handle_path_1.reverse_proxy: "{{upstreams 9944}}"
      caddy_1: \${DOMAIN_PREFIX}-\${NODE_ID}.system.\${NETWORK_NAME}.subspace.network
      caddy_1.handle_path_0: /http
      caddy_1.handle_path_0.reverse_proxy: "{{upstreams 8933}}"
      caddy_1.handle_path_1: /ws
      caddy_1.handle_path_1.reverse_proxy: "{{upstreams 8944}}"
      caddy_2: \${DOMAIN_PREFIX}-\${NODE_ID}.payments.\${NETWORK_NAME}.subspace.network
      caddy_2.handle_path_0: /http
      caddy_2.handle_path_0.reverse_proxy: "{{upstreams 7933}}"
      caddy_2.handle_path_1: /ws
      caddy_2.handle_path_1.reverse_proxy: "{{upstreams 7944}}"
    command: [
      "--chain", \$NETWORK_NAME,
      "--base-path", "/var/subspace",
      "--execution", "wasm",
      "--state-pruning", "archive",
      "--blocks-pruning", "archive",
      "--listen-addr", "/ip4/0.0.0.0/tcp/30333",
      "--no-private-ipv4",
      "--dsn-disable-private-ips",
      "--piece-cache-size", \$PIECE_CACHE_SIZE,
      "--node-key", \$NODE_KEY,
      "--rpc-cors", "all",
      "--rpc-port", "9933",
      "--ws-port", "9944",
      "--ws-external",
      "--in-peers", "500",
      "--out-peers", "250",
      "--in-peers-light", "500",
      "--ws-max-connections", "10000",
EOF

reserved_only=${1}
node_count=${2}
current_node=${3}
bootstrap_node_count=${4}

for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" != "${i}" ]; then
    addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" /subspace/node_keys.txt)
    echo "      \"--reserved-nodes\", \"${addr}\"," >> /subspace/docker-compose.yml
    echo "      \"--bootnodes\", \"${addr}\"," >> /subspace/docker-compose.yml
  fi
done

for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" /subspace/bootstrap_node_keys.txt)
  echo "      \"--reserved-nodes\", \"${addr}\"," >> /subspace/docker-compose.yml
  echo "      \"--bootnodes\", \"${addr}\"," >> /subspace/docker-compose.yml
done

if [ "${reserved_only}" == "true" ]; then
    echo "      \"--reserved-only\"," >> /subspace/docker-compose.yml
fi

{
# system domain
  echo '      "--",'
  echo "      \"--chain=\$NETWORK_NAME\","
  echo '      "--validator",'
  echo '      "--state-pruning", "archive",'
  echo '      "--blocks-pruning", "archive",'
  echo '      "--base-path", "/var/subspace/system_domain",'
  echo '      "--keystore-path", "/var/subspace/keystore",'
  echo '      "--rpc-cors", "all",'
  echo '      "--rpc-port", "8933",'
  echo '      "--ws-port", "8944",'
  echo '      "--no-private-ipv4",'
  echo '      "--unsafe-ws-external",'
  echo "      \"--relayer-id=\$RELAYER_ID\","
# core payments domain
  echo '      "--",'
  echo "      \"--chain=\$NETWORK_NAME\","
  echo '      "--validator",'
  echo '      "--state-pruning", "archive",'
  echo '      "--blocks-pruning", "archive",'
  echo '      "--domain-id", "1",'
  echo '      "--base-path", "/var/subspace/core_payments_domain",'
  echo '      "--keystore-path", "/var/subspace/keystore",'
  echo '      "--rpc-cors", "all",'
  echo '      "--rpc-port", "7933",'
  echo '      "--ws-port", "7944",'
  echo '      "--no-private-ipv4",'
  echo '      "--unsafe-ws-external",'
  echo "      \"--relayer-id=\$RELAYER_ID\","
}  >> /subspace/docker-compose.yml

echo '    ]' >> /subspace/docker-compose.yml
