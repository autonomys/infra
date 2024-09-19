output "bootstrap-node-ipv4-addresses" {
  value       = module.network.bootstrap-node-ipv4-addresses
  description = "Bootstrap node IPv4 Addresses"
}

output "bootstrap-node-evm-ipv4-addresses" {
  value       = module.network.bootstrap-node-evm-ipv4-addresses
  description = "Bootstrap node EVM IPv4 Addresses"
}

output "node-ipv4-addresses" {
  value       = module.network.node-ipv4-addresses
  description = "subspace node IPv4 Addresses"
}

output "domain-node-ipv4-addresses" {
  value       = module.network.domain-node-ipv4-addresses
  description = "domain node IPv4 Addresses"
}


output "farmer-nodes-ipv4-addresses" {
  value       = module.network.farmer-node-ipv4-addresses
  description = "Farmer node IPv4 Addresses"
}

# Output the operator_peer_multiaddr value
output "operator_peer_multiaddr" {
  value = data.external.operator_peer_multiaddr.result["operator_peer_multiaddr"]
}
