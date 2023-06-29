//output
output "full-node-ipv4-addresses" {
  value       = module.gemini-3e.full_node_public_ip
  description = "Full node IPv4 Addresses"
}

output "farmer-node-ipv4-addresses" {
  value       = module.gemini-3e.farmer_node_public_ip
  description = "Farmer node IPv4 Addresses"
}

output "bootstrap-node-ipv4-addresses" {
  value       = module.gemini-3e.bootstrap_node_public_ip
  description = "Bootstrap node IPv4 Addresses"
}

output "domain-node-ipv4-addresses" {
  value       = module.gemini-3e.domain_node_public_ip
  description = "Domain node IPv4 Addresses"
}
