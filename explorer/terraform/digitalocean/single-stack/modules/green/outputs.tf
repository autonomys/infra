output "do-explorer-node-ipv4-addresses" {
  value       = module.explorer-node.do-explorer-node-ipv4-addresses
  description = "DO Explorer node IPv4 Addresses"
}

output "rpc-records" {
  value       = module.explorer-node.rpc-records
  description = "RPC records"
}
