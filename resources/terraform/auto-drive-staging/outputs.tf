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

output "private_hostname" {
  value       = module.private.hostname
  description = "Hostname of the Auto Drive staging private backend host"
}

output "private_services" {
  value       = module.private.services
  description = "Services on the private backend host, with the loopback port each is published on"
}

output "private_hostnames" {
  value       = module.private.hostnames
  description = "Names the private backend host's nginx serves"
}

output "publish_worker_hosts" {
  value = [
    for name, services in { public = module.public.services, private = module.private.services } :
    name if contains(keys(services), "backend-publish-worker")
  ]
  description = "The backend host that runs the publish worker, the only on-chain publisher"

  precondition {
    condition = length([
      for services in [module.public.services, module.private.services] : 1
      if contains(keys(services), "backend-publish-worker")
    ]) == 1
    error_message = "Exactly one backend host must run backend-publish-worker: its signing accounts' nonces are tracked in one process, so two publishers collide."
  }
}
