output "do-explorer-node-blue-ipv4-addresses" {
  value       = module.blue.do-explorer-node-ipv4-addresses
  description = "DO Explorer node IPv4 Addresses"
}

output "do-archive-squid-node-blue-ipv4-addresses" {
  value       = module.blue.do-archive-squid-node-ipv4-addresses
  description = "DO Explorer node IPv4 Addresses"
}

output "rpc-records-blue" {
  value       = module.blue.rpc-records
  description = "RPC records"
}
