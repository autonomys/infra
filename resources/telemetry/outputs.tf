// Output Variables

output "telemetry_subspace_node_server_id" {
  value = module.telemetry_subspace_node.id
}

output "telemetry_subspace_node_public_ip" {
  value = module.telemetry_subspace_node.public_ip
}

output "telemetry_subspace_node_private_ip" {
  value = module.telemetry_subspace_node.private_ip
}

output "telemetry_subspace_node_ami" {
  value = module.telemetry_subspace_node.ami
}

output "telemetry_subspace_node_ipv4_addresses" {
  value       = module.telemetry.*.telemetry_subspace_node_public_ip
  description = "telemetry node IPv4 Addresses"
}

output "dns-records" {
  value       = module.telemetry.*.dns-records
  description = "DNS records"
}
