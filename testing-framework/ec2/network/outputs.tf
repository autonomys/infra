//output
output "node-ipv4-addresses" {
  value       = module.network.node_public_ip
  description = "Subspace node IPv4 Addresses"
}

output "farmer-node-ipv4-addresses" {
  value       = module.network.farmer_node_public_ip
  description = "Farmer node IPv4 Addresses"
}

output "bootstrap-node-ipv4-addresses" {
  value       = module.network.bootstrap_node_public_ip
  description = "Bootstrap node IPv4 Addresses"
}


output "domain-node-ipv4-addresses" {
  value       = module.network.domain_node_public_ip
  description = "Domain node IPv4 Addresses"
}

# Output the operator_peer_multiaddr value
output "operator_peer_multiaddr" {
  value = data.external.operator_peer_multiaddr.result["operator_peer_multiaddr"]
}
