output "files_gateway_hostname" {
  value       = module.files_gateway.hostname
  description = "Hostname of the Auto Drive staging files gateway"
}

output "mesh_addresses" {
  value       = { for name, host in local.mesh_hosts : name => host.address }
  description = "Private mesh address of each staging host"

  precondition {
    condition     = length(setsubtract(keys(var.mesh_public_keys), keys(local.mesh_hosts))) == 0
    error_message = "mesh_public_keys has keys that name no mesh member: ${join(", ", sort(setsubtract(keys(var.mesh_public_keys), keys(local.mesh_hosts))))}. Keys must match the names in local.mesh_hosts."
  }
}

output "services_hostname" {
  value       = module.services.hostname
  description = "Hostname of the Auto Drive staging services host"
}

output "public_hostname" {
  value       = module.public.hostname
  description = "Hostname of the Auto Drive staging public backend host"
}

output "public_services" {
  value       = module.public.services
  description = "Services on the public backend host, with the loopback port each is published on"
}

output "public_hostnames" {
  value       = module.public.hostnames
  description = "Names the public backend host's nginx serves"
}
