#!/bin/bash

EXTERNAL_IP=`curl -s -4 https://ifconfig.me`
EXTERNAL_IP_V6=`curl -s -6 https://ifconfig.me`

reserved_only=${1}
node_count=${2}
bootstrap_node_count=${3}

cat > ~/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}
  vmagentdata: {}

services:
  vmagent:
    container_name: vmagent
    image: victoriametrics/vmagent:latest
    depends_on:
      - "archival-node"
    ports:
      - 8429:8429
    volumes:
      - vmagentdata:/vmagentdata
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    command:
      - "--httpListenAddr=0.0.0.0:8429"
      - "--promscrape.config=/etc/prometheus/prometheus.yml"
      - "--remoteWrite.url=http://vmetrics.subspace.network:8428/api/v1/write"

  agent:
    container_name: newrelic-infra
    image: newrelic/infrastructure:latest
    cap_add:
      - SYS_PTRACE
    network_mode: bridge
    pid: host
    privileged: true
    volumes:
      - "/:/host:ro"
      - "/var/run/docker.sock:/var/run/docker.sock"
    environment:
      NRIA_LICENSE_KEY: "\${NR_API_KEY}"
      NRIA_DISPLAY_NAME: "\${NETWORK_NAME}-bootstrap-node-\${DOMAIN_LABEL}-\${NODE_ID}"
    restart: unless-stopped

  archival-node:
    image: ghcr.io/\${NODE_ORG}/node:\${DOCKER_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
    restart: unless-stopped
    ports:
      - "30333:30333/tcp"
      - "30433:30433/tcp"
      - "30334:30334/tcp"
      - "9615:9615"
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"
    command: [
      "run",
      "--chain", "\${NETWORK_NAME}",
      "--base-path", "/var/subspace",
      "--sync", "full",
      "--listen-on", "/ip4/0.0.0.0/tcp/30333",
      "--listen-on", "/ip6/::/tcp/30333",
      "--node-key", "\${NODE_KEY}",
      "--in-peers", "2000",
      "--out-peers", "2000",
      "--dsn-external-address", "/ip4/$EXTERNAL_IP/tcp/30433",
      "--dsn-external-address", "/ip6/$EXTERNAL_IP_V6/tcp/30433",
      "--dsn-in-connections", "2000",
      "--dsn-out-connections", "2000",
      "--dsn-pending-in-connections", "2000",
      "--dsn-pending-out-connections", "2000",
      "--prometheus-listen-on", "0.0.0.0:9615",
      "--external-address", "/ip4/$EXTERNAL_IP/tcp/30333",
      "--external-address", "/ip6/$EXTERNAL_IP_V6/tcp/30333",
EOF

for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/bootstrap_node_keys.txt)
    echo "      \"--reserved-peer\", \"${addr}\"," >> ~/subspace/docker-compose.yml
    echo "      \"--bootstrap-node\", \"${addr}\"," >> ~/subspace/docker-compose.yml
done

for (( i = 0; i < bootstrap_node_count; i++ )); do
  dsn_addr=$(sed -nr "s/NODE_${i}_SUBSPACE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
  echo "      \"--dsn-reserved-peer\", \"${dsn_addr}\"," >> ~/subspace/docker-compose.yml
  echo "      \"--dsn-bootstrap-node\", \"${dsn_addr}\"," >> ~/subspace/docker-compose.yml
done

if [ "${reserved_only}" == true ]; then
    echo "      \"--reserved-only\"," >> ~/subspace/docker-compose.yml
fi

{
    # domain args
    echo '      "--",'
    echo '      "--domain-id", "${DOMAIN_ID}",'
    echo '      "--listen-on", "/ip4/0.0.0.0/tcp/30334",'
    echo '      "--listen-on", "/ip6/::/tcp/30334",'
    echo '      "--public-addr", "/ip4/'"$EXTERNAL_IP"'/tcp/30334",'
    echo '      "--public-addr", "/ip6/'"$EXTERNAL_IP_V6"'/tcp/30334",'
    for (( i = 0; i < node_count; i++ )); do
      addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/node_keys.txt)
      echo "      \"--reserved-peer\", \"${addr}\","
      echo "      \"--bootstrap-node\", \"${addr}\","
    done
    if [ "${reserved_only}" == true ]; then
        echo "      \"--reserved-only\","
    fi
    echo '    ]'
}  >> ~/subspace/docker-compose.yml
