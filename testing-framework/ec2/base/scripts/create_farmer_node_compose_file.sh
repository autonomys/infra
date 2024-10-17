#!/bin/bash

EXTERNAL_IP=`curl -s -4 https://ifconfig.me`
EXTERNAL_IP_V6=`curl -s -6 https://ifconfig.me`

cat > ~/subspace/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}
  farmer_data: {}

services:
  farmer:
    depends_on:
      archival-node:
        condition: service_healthy
    build:
      context: .
      dockerfile: /home/ubuntu/subspace/subspace/Dockerfile-farmer
    image: ghcr.io/\${REPO_ORG}/farmer:\${DOCKER_TAG}
    volumes:
      - /home/$USER/subspace/farmer_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30533:30533/tcp"
      - "9616:9616"
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"
    command: [
      "farm", "path=/var/subspace,size=\${PLOT_SIZE}",
      "--node-rpc-url", "ws://archival-node:9944",
      "--external-address", "/ip4/$EXTERNAL_IP/tcp/30533",
      "--external-address", "/ip6/$EXTERNAL_IP_V6/tcp/30533",
      "--listen-on", "/ip4/0.0.0.0/tcp/30533",
      "--listen-on", "/ip6/::/tcp/30533",
      "--reward-address", "\${REWARD_ADDRESS}",
      "--metrics-endpoint=0.0.0.0:9616",
      "--cache-percentage", "\${CACHE_PERCENTAGE}",
      "--farming-thread-pool-size", "\${THREAD_POOL_SIZE}",
    ]

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
#      "--pot-external-entropy", "\${POT_EXTERNAL_ENTROPY}",
      "--listen-on", "/ip4/0.0.0.0/tcp/30333",
      "--listen-on", "/ip6/::/tcp/30333",
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/tcp/30433",
      "--dsn-external-address", "/ip6/$EXTERNAL_IP_V6/tcp/30433",
      "--node-key", "\${NODE_KEY}",
      "--farmer",
      "--timekeeper",
      "--rpc-cors", "all",
      "--rpc-listen-on", "0.0.0.0:9944",
      "--rpc-methods", "unsafe",
      "--prometheus-listen-on", "0.0.0.0:9615",
EOF

reserved_only=${1}
node_count=${2}
current_node=${3}
bootstrap_node_count=${4}
dsn_bootstrap_node_count=${4}
force_block_production=${5}

for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace//bootstrap_node_keys.txt)
  echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--bootstrap-nodes\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

for (( i = 0; i < dsn_bootstrap_node_count; i++ )); do
  dsn_addr=$(sed -nr "s/NODE_${i}_SUBSPACE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
  echo "      \"--dsn-reserved-peers\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--dsn-bootstrap-nodes\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

if [ "${reserved_only}" == true ]; then
  echo "      \"--reserved-only\"," >> ~/subspace/subspace/docker-compose.yml
fi

if [ "${force_block_production}" == true ]; then
  echo "      \"--force-synced\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--force-authoring\"," >> ~/subspace/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/subspace/docker-compose.yml
