#!bin/sh

. env.sh
# Install Certificates
ssh certbot certonly --nginx -d ${RELAYER_DNS_NAME}.subspace.network  --non-interactive --agree-tos --email admin@subspace.network

scp -r -o "ForwardAgent=yes" -o "StrictHostKeyChecking=no" root@${ARCHIVE_NODE_IP_ADDRESS}:/mnt/polkadot_archive_volume/polkadot-archives/ root@${RELAYER_DNS_NAME}:/mnt/relaynet_test_volume/polkadot-archives
scp -r -o "ForwardAgent=yes" -o "StrictHostKeyChecking=no" root@${ARCHIVE_NODE_IP_ADDRESS}:/mnt/kusama_archive_volume/polkadot-archives/ root@${RELAYER_DNS_NAME}:/mnt/relaynet_test_volume/kusama-archives