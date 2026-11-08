output "loki_domain" {
  value       = module.monitoring.loki_domain
  description = "Hostname the fleet pushes logs to"
}

output "stack_dir" {
  value       = module.monitoring.stack_dir
  description = "Directory on the host holding the compose stack"
}
