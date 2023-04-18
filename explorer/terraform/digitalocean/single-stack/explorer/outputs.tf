output "do-explorer-node-blue-ipv4-addresses" {
  value       = module.explorer-node-blue.explorer-node-ipv4-addresses
  description = "DO Explorer blue node IPv4 Addresses"
}

output "do-archive-node-blue-ipv4-addresses" {
  value       = module.squid-archive-node-blue.squid-archive-node-ipv4-addresses
  description = "DO Archive blue node IPv4 Addresses"
}

output "do-explorer-node-green-ipv4-addresses" {
  value       = module.explorer-node-green.explorer-node-ipv4-addresses
  description = "DO Explorer green node IPv4 Addresses"
}

output "do-archive-node-green-ipv4-addresses" {
  value       = module.squid-archive-node-green.squid-archive-node-ipv4-addresses
  description = "DO Archive green node IPv4 Addresses"
}
