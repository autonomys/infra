#!/bin/bash

EXTERNAL_IP=`curl -s -4 https://ifconfig.me`
EXTERNAL_IP_V6=`curl -s -6 https://ifconfig.me`

cat > ~/subspace/subspace/docker-compose.yml << EOF
version: "3.7"

volumes:
  archival_node_data: {}

networks:
  traefik-proxy:

services:
  # traefik reverse proxy with automatic tls management using let encrypt
  traefik:
    image: traefik:v3.1.6
    container_name: traefik
    restart: unless-stopped
    command:
      - --api=false
      - --api.dashboard=false
      - --providers.docker
      - --log.level=info
      - --entrypoints.web.address=:80
      - --entrypoints.web.http.redirections.entryPoint.to=websecure
      - --entrypoints.websecure.address=:443
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --certificatesresolvers.le.acme.email=alerts@subspace.network
      - --certificatesresolvers.le.acme.storage=/acme.json
      - --certificatesresolvers.le.acme.tlschallenge=true
      - "traefik.docker.network=traefik-proxy"
    networks:
      - traefik-proxy
    ports:
      - 80:80
      - 443:443
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./letsencrypt/acme.json:/acme.json

  archival-node:
    build:
      context: .
      dockerfile: /home/ubuntu/subspace/subspace/Dockerfile-node
    image: ghcr.io/\${REPO_ORG}/node:\${DOCKER_TAG}
    volumes:
      - archival_node_data:/var/subspace:rw
      - ./keystore:/var/subspace/keystore:ro
    restart: unless-stopped
    ports:
      - "30333:30333/tcp"
      - "30433:30433/tcp"
      - "30334:30334/tcp"
      - "9615:9615"
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.archival-node.loadbalancer.server.port=8944"
      - "traefik.http.routers.archival-node.rule=Host(\`\${DOMAIN_PREFIX_AUTO}-\${DOMAIN_ID_AUTO}.\${NETWORK_NAME}.subspace.network\`) && Path(\`/ws\`)"
      - "traefik.http.routers.archival-node.tls=true"
      - "traefik.http.routers.archival-node.tls.certresolver=le"
      - "traefik.http.routers.archival-node.entrypoints=websecure"
      - "traefik.http.routers.archival-node.middlewares=redirect-https"
      - "traefik.http.middlewares.redirect-https.redirectscheme.scheme=https"
      - "traefik.http.middlewares.redirect-https.redirectscheme.permanent=true"
      - "traefik.docker.network=traefik-proxy"
    networks:
      - traefik-proxy
    logging:
      driver: loki
      options:
        loki-url: "https://logging.subspace.network/loki/api/v1/push"
    command: [
      "run",
      "--chain", "\${NETWORK_NAME}",
      "--base-path", "/var/subspace",
      "--state-pruning", "archive",
      "--blocks-pruning", "archive",
      "--pot-external-entropy", "\${POT_EXTERNAL_ENTROPY}",
      "--listen-on", "/ip4/0.0.0.0/tcp/30333",
      "--listen-on", "/ip6/::/tcp/30333",
      "--node-key", "\${NODE_KEY}",
      "--dsn-in-connections", "500",
      "--dsn-out-connections", "250",
      "--in-peers", "250",
      "--out-peers", "150",
      "--rpc-max-connections", "1000",
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
bootstrap_node_autoid_count=${5}
enable_domains=${6}
domain_id=${7}

for (( i = 0; i < node_count; i++ )); do
  if [ "${current_node}" == "${i}" ]; then
    dsn_addr=$(sed -nr "s/NODE_${i}_DSN_MULTI_ADDR=//p" ~/subspace/node_keys.txt)
    echo "      \"--dsn-external-address\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
  fi
done

for (( i = 0; i < bootstrap_node_count; i++ )); do
  addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace//bootstrap_node_keys.txt)
  echo "      \"--reserved-peer\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--bootstrap-node\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

for (( i = 0; i < dsn_bootstrap_node_count; i++ )); do
  dsn_addr=$(sed -nr "s/NODE_${i}_SUBSPACE_MULTI_ADDR=//p" ~/subspace/dsn_bootstrap_node_keys.txt)
  echo "      \"--dsn-reserved-peer\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
  echo "      \"--dsn-bootstrap-node\", \"${dsn_addr}\"," >> ~/subspace/subspace/docker-compose.yml
done

if [ "${reserved_only}" == "true" ]; then
    echo "      \"--reserved-only\"," >> ~/subspace/subspace/docker-compose.yml
fi

if [ "${enable_domains}" == "true" ]; then
  {
    # auto domain
    echo '      "--",'
    echo '      "--domain-id", "${DOMAIN_ID_AUTO}",'
    echo '      "--state-pruning", "archive",'
    echo '      "--blocks-pruning", "archive",'
    echo '      "--operator-id", "0",'
    echo '      "--listen-on", "/ip4/0.0.0.0/tcp/30334",'
    echo '      "--listen-on", "/ip6/::/tcp/30334",'
    echo '      "--rpc-cors", "all",'
    echo '      "--rpc-methods", "safe",'
    echo '      "--rpc-listen-on", "0.0.0.0:8944",'
    echo '      "--rpc-max-connections", "10000",'

    for (( i = 0; i < bootstrap_node_autoid_count; i++ )); do
      addr=$(sed -nr "s/NODE_${i}_MULTI_ADDR=//p" ~/subspace/bootstrap_node_autoid_keys.txt)
      echo "      \"--reserved-peer\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
      echo "      \"--bootstrap-node\", \"${addr}\"," >> ~/subspace/subspace/docker-compose.yml
    done

  } >> ~/subspace/subspace/docker-compose.yml
fi

echo '    ]' >> ~/subspace/subspace/docker-compose.yml
