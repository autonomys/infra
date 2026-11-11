output "files_gateway_hostname" {
  value       = module.files_gateway.hostname
  description = "Hostname of the Auto Drive staging files gateway"
}

output "files_gateway_services" {
  value       = module.files_gateway.services
  description = "Gateway services started on the files gateway host"
}
