#!/bin/bash

# Function to retrieve key-value pair from AWS KMS
get_from_kms() {
  local node_name=$1
  local aws_region="us-east-2"
  local kms_key_id="arn:aws:kms:us-west-2:123456789012:key/abcd1234-a123-1234-a123-123456789012"

  # Get the encrypted data from KMS
  local encrypted_data=$(aws kms decrypt \
    --ciphertext-blob fileb://<(aws kms encrypt \
      --key-id ${kms_key_id} \
      --plaintext "key=${node_name}" \
      --region ${aws_region} \
      --output text \
      --query CiphertextBlob) \
    --region ${aws_region} \
    --output text \
    --query Plaintext | base64 --decode)

  echo "${encrypted_data}"
}

# Function to restore keys for a specific node type
restore_node_keys() {
  local node_type=$1
  local count=$2

  for i in $(seq 0 $((count-1))); do
    local node_name="${node_type}-${i}"
    echo "Restoring keys for ${node_name}..."

    # Get the key data from KMS
    local key_data=$(get_from_kms "${node_name}")

    # Extract the key and peer ID
    local node_key=$(echo "${key_data}" | grep -oP '(?<=value=).*')
    local peer_id=$(echo "${key_data}" | grep -oP '(?<=key=).*(?= value)')

    # Create the key file
    echo "${peer_id}" > "${node_name}.key"
    echo "${node_key}" >> "${node_name}.key"

    echo "Restored keys for ${node_name}"
  done
}

# Restore keys for all node types
restore_node_keys "bootstrap" 2
restore_node_keys "rpc" 2
restore_node_keys "nova" 2
restore_node_keys "autoid" 2
restore_node_keys "farmer" 1
restore_node_keys "nova-bootstrap" 2
restore_node_keys "autoid-bootstrap" 2

echo "Node key restoration completed."
