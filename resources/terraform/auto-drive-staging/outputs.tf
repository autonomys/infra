output "files_gateway_hostname" {
  value       = module.files_gateway.hostname
  description = "Hostname of the Auto Drive staging files gateway"
}

output "files_gateway_services" {
  value       = module.files_gateway.services
  description = "Gateway services started on the files gateway host"
}

output "mesh_addresses" {
  value       = { for name, host in local.mesh_hosts : name => host.address }
  description = "Private mesh address of each staging host"
}
