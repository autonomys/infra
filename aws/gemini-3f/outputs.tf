//output
output "full-node-ipv4-addresses" {
  value       = module.gemini-3f.full_node_public_ip
  description = "Full node IPv4 Addresses"
}

output "farmer-node-ipv4-addresses" {
  value       = module.gemini-3f.farmer_node_public_ip
  description = "Farmer node IPv4 Addresses"
}

output "bootstrap-node-ipv4-addresses" {
  value       = module.gemini-3f.bootstrap_node_public_ip
  description = "Bootstrap node IPv4 Addresses"
}

output "bootstrap-node-evm-ipv4-addresses" {
  value       = module.gemini-3f.bootstrap_node_evm_public_ip
  description = "EVM Bootstrap node IPv4 Addresses"
}

output "domain-node-ipv4-addresses" {
  value       = module.gemini-3f.domain_node_public_ip
  description = "Domain node IPv4 Addresses"
}

output "rpc-node-ipv4-addresses" {
  value       = module.gemini-3f.rpc_node_public_ip
  description = "RPC node IPv4 Addresses"
}
