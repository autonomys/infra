output "staging_host_ipv4" {
  value       = module.auto_drive_staging.host_ipv4
  description = "Auto Drive staging host public IPv4"
}

output "staging_primary_domain" {
  value       = module.auto_drive_staging.primary_domain
  description = "Auto Drive staging primary domain"
}

output "staging_download_domain" {
  value       = module.auto_drive_staging.download_domain
  description = "Auto Drive staging download domain"
}

output "staging_compose_file" {
  value       = module.auto_drive_staging.compose_file
  description = "Compose file on the host that the deploy playbook invokes"
}
