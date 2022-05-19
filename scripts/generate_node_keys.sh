#!/bin/zsh

docker pull subspacelabs/subspace-node:latest
node_count=${1}
output_file=${2}
if [ -s "${output_file}" ]; then
    echo "Node keys exists..."
    exit 0
fi
ips=$(echo "$NODE_PUBLIC_IPS" | awk -F, '{for(i=1;i<=NF;i++) print $i}')
ips=("${(f)ips}")
echo -n > "${output_file}"
echo -n > /tmp/additionl_args.txt
echo "Generating node keys..."
for (( i = 0; i < node_count; i++ )); do
    docker run --rm subspacelabs/subspace-node key generate-node-key &> /tmp/log.txt
    peer_id=$(sed '2q;d' /tmp/log.txt)
    node_key=$(sed '3q;d' /tmp/log.txt)
    (( ip_idx = ${i} + 1 ))
    {
      echo "NODE_${i}_PEER_ID=${peer_id}"
      echo "NODE_${i}_KEY=${node_key}"
      echo "NODE_${i}_MULTI_ADDR=/ip4/${ips[${ip_idx}]}/tcp/30333/p2p/${peer_id}"
    } >> "${output_file}"
done
echo "Done."
