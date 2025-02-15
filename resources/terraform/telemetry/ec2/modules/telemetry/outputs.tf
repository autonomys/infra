output "telemetry_subspace_node_ipv4_addresses" {
  value       = module.telemetry.*.telemetry_subspace_node_public_ip
  description = "telemetry node IPv4 Addresses"
}

output "dns-records" {
  value       = module.telemetry.*.dns-records
  description = "DNS records"
}
