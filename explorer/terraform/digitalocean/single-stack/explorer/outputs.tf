output "do-explorer-node-blue-ipv4-addresses" {
  value       = module.blue.do-explorer-node-ipv4-addresses
  description = "DO Explorer blue node IPv4 Addresses"
}

output "do-explorer-node-green-ipv4-addresses" {
  value       = module.green.do-explorer-node-ipv4-addresses
  description = "DO Explorer green node IPv4 Addresses"
}

output "do-archive-node-blue-ipv4-addresses" {
  value       = module.blue.do-archive-node-ipv4-addresses
  description = "DO Archive blue node IPv4 Addresses"
}

output "do-archive-node-green-ipv4-addresses" {
  value       = module.green.do-archive-node-ipv4-addresses
  description = "DO Archive green node IPv4 Addresses"
}
