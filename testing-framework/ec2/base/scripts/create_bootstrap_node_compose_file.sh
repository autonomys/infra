#!/bin/bash

EXTERNAL_IP=`curl -s -4 https://ifconfig.me`
EXTERNAL_IP_V6=`curl -s -6 https://ifconfig.me`

reserved_only=${1}
node_count=${2}
current_node=${3}

cat > ~/subspace/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}

services:
  dsn-bootstrap-node:
    build:
      context: .
      dockerfile: /home/ubuntu/subspace/subspace/Dockerfile-bootstrap-node
    image: ghcr.io/\${REPO_ORG}/bootstrap-node:\${DOCKER_TAG}
    restart: unless-stopped
    environment:
      - RUST_LOG=info
    ports:
      - "30533:30533/tcp"
      - "9616:9616"
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"
    command:
      - start
      - "--prometheus-listen-on=0.0.0.0:9616"
      - "--keypair"
      - \${DSN_NODE_KEY}
      - "--listen-on"
      - /ip4/0.0.0.0/tcp/30533
      - "--listen-on"
      - /ip6/::/tcp/30533
      - --protocol-version
      - \${GENESIS_HASH}
      - "--in-peers"
      - "1000"
      - "--out-peers"
      - "1000"
      - "--pending-in-peers"
      - "1000"
      - "--pending-out-peers"
      - "1000"
## comment to disable external addresses using IP format for now
#      - "--external-address"
#      - "/ip4/$EXTERNAL_IP/tcp/30533"
#      - "--external-address"
#      - "/ip6/$EXTERNAL_IP_V6/tcp/30533"
EOF

for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" == "${i}" ]; then
    dsn_addr=$(sed -nr "s/NODE_${i}_SUBSPACE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
    echo "      - \"--external-address\"" >> ~/subspace/subspace/docker-compose.yml
    echo "      - \"${dsn_addr}\"" >> ~/subspace/subspace/docker-compose.yml
  fi
done

for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" != "${i}" ]; then
    dsn_addr=$(sed -nr "s/NODE_${i}_SUBSPACE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
    echo "      - \"--reserved-peer\"" >> ~/subspace/subspace/docker-compose.yml
    echo "      - \"${dsn_addr}\"" >> ~/subspace/subspace/docker-compose.yml
    echo "      - \"--bootstrap-node\"" >> ~/subspace/subspace/docker-compose.yml
    echo "      - \"${dsn_addr}\"" >> ~/subspace/subspace/docker-compose.yml
  fi
done

cat >> ~/subspace/subspace/docker-compose.yml << EOF
  archival-node:
    build:
      context: .
      dockerfile: /home/ubuntu/subspace/subspace/Dockerfile-node
    image: ghcr.io/\${REPO_ORG}/node:\${DOCKER_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333/tcp"
      - "30433:30433/tcp"
      - "9615:9615"
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"
    command: [
      "run",
      "--chain", "\${NETWORK_NAME}",
      "--base-path", "/var/subspace",
      "--state-pruning", "archive",
      "--blocks-pruning", "256",
      "--pot-external-entropy", "\${POT_EXTERNAL_ENTROPY}",
      "--listen-on", "/ip4/0.0.0.0/tcp/30333",
      "--listen-on", "/ip6/::/tcp/30333",
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/tcp/30433",
      "--dsn-external-address", "/ip6/$EXTERNAL_IP_V6/tcp/30433",
      "--node-key", "\${NODE_KEY}",
      "--in-peers", "1000",
      "--out-peers", "1000",
      "--dsn-in-connections", "1000",
      "--dsn-out-connections", "1000",
      "--dsn-pending-in-connections", "1000",
      "--dsn-pending-out-connections", "1000",
      "--prometheus-listen-on", "0.0.0.0:9615",
EOF

for (( i = 0; i < node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/node_keys.txt)
  echo "      \"--reserved-peer\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--bootstrap-node\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

if [ "${reserved_only}" == true ]; then
    echo "      \"--reserved-only\"," >> ~/subspace/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/subspace/docker-compose.yml
