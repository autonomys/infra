#!/bin/bash
set -e

EXTERNAL_IP=$(curl -s -4 https://ifconfig.me)

cat > ~/subspace/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}

services:
  archival-node:
    build:
      context: .
      dockerfile: $HOME/subspace/subspace/Dockerfile-node
    image: \${REPO_ORG}/\${NODE_TAG}:latest
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333/udp"
      - "30433:30433/udp"
      - "30333:30333/tcp"
      - "30433:30433/tcp"
      - "30334:30334"
      - "9615:9615"
    command: [
      "run",
      "--chain", "\${NETWORK_NAME}",
      "--base-path", "/var/subspace",
      "--state-pruning", "archive",
      "--blocks-pruning", "archive",
      "--listen-on", "/ip4/0.0.0.0/tcp/30333",
## comment to disable dsn external addresses using IP format for now
#      "--dsn-external-address", "/ip4/$EXTERNAL_IP/udp/30433/quic-v1",
#      "--dsn-external-address", "/ip4/$EXTERNAL_IP/tcp/30433",
      "--node-key", "\${NODE_KEY}",
      "--in-peers", "500",
      "--out-peers", "250",
      "--rpc-max-connections", "10000",
      "--rpc-cors", "all",
      "--rpc-listen-on", "0.0.0.0:9944",
      "--rpc-methods", "safe",
      "--prometheus-listen-on", "0.0.0.0:9615",
EOF

reserved_only=${1}
node_count=${2}
current_node=${3}
bootstrap_node_count=${4}
dsn_bootstrap_node_count=${4}
enable_domains=${5}
domain_id=${6}

for (( i = 0; i < node_count; i++ )); do
  dsn_addr=$(sed -nr "s/NODE_${i}_SUBSTRATE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
  echo "      - \"--dsn-external-address\"" >> ~/subspace/docker-compose.yml
  echo "      - \"${dsn_addr}\"" >> ~/subspace/docker-compose.yml
  dsn_addr=$(sed -nr "s/NODE_${i}_SUBSTRATE_MULTI_ADDR_TCP=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
  echo "      - \"--dsn-external-address\"" >> ~/subspace/docker-compose.yml
  echo "      - \"${dsn_addr}\"" >> ~/subspace/docker-compose.yml
done

for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace//bootstrap_node_keys.txt)
  echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--bootstrap-nodes\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

#// TODO: make configurable with gemini network as it's not needed for devnet
for (( i = 0; i < dsn_bootstrap_node_count; i++ )); do
  dsn_addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
  echo "      \"--dsn-reserved-peers\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--dsn-bootstrap-nodes\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

if [ "${reserved_only}" == "true" ]; then
    echo "      \"--reserved-only\"," >> ~/subspace/subspace/docker-compose.yml
fi

if [ "${enable_domains}" == "true" ]; then
    {
    # core domain
    echo '      "--",'
    echo '      "--domain-id", "${DOMAIN_ID}",'
    echo '      "--state-pruning", "archive",'
    echo '      "--blocks-pruning", "archive",'
    echo '      "--operator-id", "0",'
    echo '      "--listen-on", "/ip4/0.0.0.0/tcp/30334",'
    echo '      "--rpc-cors", "all",'
    echo '      "--rpc-methods", "safe",'
    echo '      "--rpc-listen-on", "0.0.0.0:8944",'

    for (( i = 0; i < bootstrap_node_evm_count; i++ )); do
      addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/bootstrap_node_evm_keys.txt)
      echo "      \"--reserved-nodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
      echo "      \"--bootstrap-nodes\", \"${addr}\"," >> ~/subspace/docker-compose.yml
    done

    }  >> ~/subspace/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/subspace/docker-compose.yml
