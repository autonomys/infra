output "do-full-node-ipv4-addresses" {
  value       = module.devnet.do-full-node-ipv4-addresses
  description = "DO full node IPv4 Addresses"
}

output "do-farmer-node-ipv4-addresses" {
  value       = module.devnet.do-farmer-node-ipv4-addresses
  description = "DO Farmer node IPv4 Addresses"
}

output "do-bootstrap-node-ipv4-addresses" {
  value       = module.devnet.do-bootstrap-node-ipv4-addresses
  description = "DO Bootstrap node IPv4 Addresses"
}

output "do-rpc-node-ipv4-addresses" {
  value       = module.devnet.do-rpc-node-ipv4-addresses
  description = "DO RPC node IPv4 Addresses"
}

output "rpc-records" {
  value       = module.devnet.rpc-records
  description = "RPC records"
}