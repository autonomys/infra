//output
output "full-node-ipv4-addresses" {
  value       = module.devnet.full_node_public_ip
  description = "Full node IPv4 Addresses"
}

output "farmer-node-ipv4-addresses" {
  value       = module.devnet.farmer_node_public_ip
  description = "Farmer node IPv4 Addresses"
}

output "bootstrap-node-ipv4-addresses" {
  value       = module.devnet.bootstrap_node_public_ip
  description = "Bootstrap node IPv4 Addresses"
}

output "rpc-node-ipv4-addresses" {
  value       = module.devnet.rpc_node_public_ip
  description = "Domain node IPv4 Addresses"
}

output "domain-node-ipv4-addresses" {
  value       = module.devnet.domain_node_public_ip
  description = "Domain node IPv4 Addresses"
}
