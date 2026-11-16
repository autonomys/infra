output "host_ipv4" {
  value = var.host.ipv4
}

output "hostname" {
  value = var.host.hostname
}

output "deploy_dir" {
  value = local.deploy_dir
}

output "services" {
  description = "Compose services the host's profiles run, with the host port each is published on"
  value       = local.ports
}

output "hostnames" {
  description = "Names the host's nginx serves"
  value       = compact([var.ingress.hostnames.app, var.ingress.hostnames.s3, var.ingress.hostnames.gateway])
}

output "migrations_id" {
  description = "Changes whenever this host has run the backend's migrations, for a host sharing its database to order its deploy after"
  value       = join("", null_resource.migrate[*].id)
}
