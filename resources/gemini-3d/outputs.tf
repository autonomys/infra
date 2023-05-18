output "do-full-node-ipv4-addresses" {
  value       = module.gemini-3d.do-full-node-ipv4-addresses
  description = "DO full node IPv4 Addresses"
}

output "do-bootstrap-node-ipv4-addresses" {
  value       = module.gemini-3d.do-bootstrap-node-ipv4-addresses
  description = "DO Bootstrap node IPv4 Addresses"
}

output "do-rpc-node-ipv4-addresses" {
  value       = module.gemini-3d.do-rpc-node-ipv4-addresses
  description = "DO RPC node IPv4 Addresses"
}

output "do-domain-node-ipv4-addresses" {
  value       = module.gemini-3d.do-domain-node-ipv4-addresses
  description = "DO domain node IPv4 Addresses"
}

output "bootstrap-node-ipv4-addresses" {
  value       = var.bootstrap_node_ips
  description = "Bootstrap node IPv4 Addresses"
}

output "full-node-ipv4-addresses" {
  value       = var.full_node_ips
  description = "full node IPv4 Addresses"
}

output "rpc-node-ipv4-addresses" {
  value       = var.rpc_node_ips
  description = "rpc node IPv4 Addresses"
}

output "domain-node-ipv4-addresses" {
  value       = var.domain_node_ips
  description = "domain node IPv4 Addresses"
}


output "rpc-records" {
  value       = module.gemini-3d.rpc-records
  description = "RPC records"
}

output "farmer-nodes" {
  value       = module.gemini-3d.do-farmer-node-ipv4-addresses
  description = "Farmer node records"
}
