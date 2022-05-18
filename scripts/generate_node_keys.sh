#!/bin/bash

docker pull subspacelabs/subspace-node:latest
node_count=${1}
output_file=${2}
if [ -s "${output_file}" ]; then
    echo "Node keys exists..."
    exit 0
fi
#TODO: how are IPS passed?
ips=${NODE_PUBLIC_IPS}
echo -n > "${output_file}"
echo "Generating node keys..."
for (( i = 0; i < node_count; i++ )); do
    keys=( $(docker run --rm -it subspacelabs/subspace-node key generate-node-key 2> /tmp/log.txt) )
    peer_id=${keys[0]}
    node_key=${keys[1]}

    {
      echo "NODE_${i}_PEER_ID=${peer_id}"
      echo "NODE_${i}_KEY=${node_key}"
      echo "NODE_${i}_MULTI_ADDR=/ip4/${ips[${i}]}/tcp/30333/p2p/${peer_id}"
    } >> "${output_file}"
done
echo "Done."
