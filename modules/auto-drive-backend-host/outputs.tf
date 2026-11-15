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
  value       = compact([var.ingress.hostnames.app, var.ingress.hostnames.s3, var.ingress.hostnames.gateway, try(var.ingress.auth.hostname, null)])
}

output "migrations_id" {
  description = "Changes whenever this host has run the backend's migrations, for a host sharing its database to order its deploy after"
  value       = join("", null_resource.migrate[*].id)
}

output "deploy_id" {
  description = "Changes whenever this host's deploy runs, which starts Hasura and installs nginx and the certificate; a host sharing its database, or a service nginx here serves, orders its own deploy after it"
  value       = null_resource.deploy.id
}

output "bootstrap_id" {
  description = "Changes whenever the host is bootstrapped again, for another role on this host to be set up again with it"
  value       = module.host.bootstrap_id
}

output "staging_dir" {
  description = "Directory on the host that the bootstrap creates for roles to upload files to"
  value       = module.host.staging_dir
}
