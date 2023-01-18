output "do-full-node-ipv4-addresses" {
  value       = module.gemini-3c.do-full-node-ipv4-addresses
  description = "DO full node IPv4 Addresses"
}

output "do-bootstrap-node-ipv4-addresses" {
  value       = module.gemini-3c.do-bootstrap-node-ipv4-addresses
  description = "DO Bootstrap node IPv4 Addresses"
}

output "do-rpc-node-ipv4-addresses" {
  value       = module.gemini-3c.do-rpc-node-ipv4-addresses
  description = "DO RPC node IPv4 Addresses"
}

output "hetzner-bootstrap-node-ipv4-addresses" {
  value       = var.hetzner_bootstrap_node_ips
  description = "Hetzner Bootstrap node IPv4 Addresses"
}

output "hetzner-full-node-ipv4-addresses" {
  value       = var.hetzner_full_node_ips
  description = "Hetzner full node IPv4 Addresses"
}

output "hetzner-rpc-node-ipv4-addresses" {
  value       = var.hetzner_rpc_node_ips
  description = "Hetzner rpc node IPv4 Addresses"
}

output "rpc-records" {
  value       = module.gemini-3c.rpc-records
  description = "RPC records"
}
