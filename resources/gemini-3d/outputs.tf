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

output "hetzner-domain-node-ipv4-addresses" {
  value       = var.hetzner_domain_node_ips
  description = "Hetzner domain node IPv4 Addresses"
}


output "rpc-records" {
  value       = module.gemini-3d.rpc-records
  description = "RPC records"
}

output "farmer-nodes" {
  value       = module.gemini-3d.do-farmer-node-ipv4-addresses
  description = "Farmer node records"
}
