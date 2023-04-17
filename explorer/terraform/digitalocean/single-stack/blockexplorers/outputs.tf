output "do-explorer-node-ipv4-addresses" {
  value       = module.explorer-node.explorer-node-ipv4-addresses
  description = "DO Explorer blue node IPv4 Addresses"
}

output "do-archive-node-ipv4-addresses" {
  value       = module.squid-archive-node.squid-archive-node-ipv4-addresses
  description = "DO Archive blue node IPv4 Addresses"
}
