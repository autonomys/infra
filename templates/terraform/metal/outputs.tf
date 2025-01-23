output "node-ipv4-addresses" {
  value       = local.node_ip_v4
  description = "Subspace node IPv4 Addresses"
}

output "farmer-node-ipv4-addresses" {
  value       = local.farmer_node_ipv4
  description = "Farmer node IPv4 Addresses"
}

output "bootstrap-node-ipv4-addresses" {
  value       = local.bootstrap_nodes_ip_v4
  description = "Bootstrap node IPv4 Addresses"
}

output "bootstrap-node-domain-ipv4-addresses" {
  value       = local.bootstrap_nodes-domain_ip_v4
  description = "Bootstrap node domain IPv4 Addresses"
}

output "domain-node-ipv4-addresses" {
  value       = local.domain_node_ip_v4
  description = "domain node IPv4 Addresses"
}
