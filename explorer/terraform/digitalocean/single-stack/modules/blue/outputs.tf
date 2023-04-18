output "do-explorer-node-ipv4-addresses" {
  value       = module.archive-squid-node.do-archive-squid-node-ipv4-addresses
  description = "DO Explorer node IPv4 Addresses"
}

output "rpc-records" {
  value       = module.archive-squid-node.rpc-records
  description = "RPC records"
}
