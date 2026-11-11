output "bootstrap_id" {
  description = "Changes whenever the bootstrap re-runs, for roles to depend on"
  value       = null_resource.bootstrap.id
}
