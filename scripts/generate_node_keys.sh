#!/bin/bash

# Function to check if subkey is installed
check_subkey() {
  if ! command -v subkey &> /dev/null; then
    echo "subkey not found. Installing..."
    curl https://getsubstrate.io -sSf | bash -s -- --fast
    cargo install --force subkey --git https://github.com/paritytech/substrate --locked
  else
    echo "subkey is already installed."
  fi
}

# Function to generate node key and store in a file
# Generate node key and store in a file
generate_node_key() {
  local node_type=$1
  local node_index=$2

  local key_file="${node_type}-${node_index}.key"
  subkey generate-node-key 2>&1 | tee "${key_file}"
  echo -e "\nGenerated node key for ${node_type}-${node_index}"
}

# Function to add key-value pair to AWS KMS
add_to_kms() {
  local key_file=$1

  local key_id=$(sed -n '1p' "${key_file}")
  local key_value=$(sed -n '2p' "${key_file}")
  local node_name=$(basename "${key_file}" .key)

  # Add key-value pair to AWS KMS using API call
  local kms_key_id="arn:aws:kms:us-east-2:123456789012:key/abcd1234-a123-1234-a123-123456789012" # Replace with your KMS key ID
  local aws_region="us-east-2"

  aws kms encrypt --key-id ${kms_key_id} --plaintext "key=${key_id} value=${key_value}" --region ${aws_region}
  echo -e "\nAdded key-value pair to AWS KMS: ${node_name} = ${key_id}=${key_value}"
}

# Check and install subkey if needed
check_subkey

# Generate node keys for bootstrap nodes
for i in {0..1}; do
  generate_node_key "bootstrap" "${i}"
done

# Generate node keys for rpc nodes
for i in {0..1}; do
  generate_node_key "rpc" "${i}"
done

# Generate node keys for auto-evm nodes
for i in {0..1}; do
  generate_node_key "auto-evm" "${i}"
done

# Generate node keys for autoid nodes
for i in {0..1}; do
  generate_node_key "autoid" "${i}"
done

# Generate node key for farmer node
generate_node_key "farmer" "0"

# Generate node keys for auto-evm-bootstrap nodes
for i in {0..1}; do
  generate_node_key "auto-evm-bootstrap" "${i}"
done

# Generate node keys for autoid-bootstrap nodes
for i in {0..1}; do
  generate_node_key "autoid-bootstrap" "${i}"
done

# Add generated keys to AWS KMS
for key_file in *.key; do
  add_to_kms "${key_file}"
done

echo "Node key generation and Vault storage completed."
