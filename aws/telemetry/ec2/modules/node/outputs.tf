output "telemetry_subspace_node_ipv4_addresses" {
  value       = module.node.*.telemetry_subspace_node_public_ip
  description = "Explorer node IPv4 Addresses"
}

output "dns-records" {
  value       = module.node.*.dns-records
  description = "DNS records"
}
