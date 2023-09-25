output "bootstrap-node-ipv4-addresses" {
  value       = module.network.bootstrap-node-ipv4-addresses
  description = "Bootstrap node IPv4 Addresses"
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
