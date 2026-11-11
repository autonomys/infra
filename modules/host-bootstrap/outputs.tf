output "bootstrap_id" {
  description = "Changes whenever the bootstrap re-runs, for roles to depend on"
  value       = null_resource.bootstrap.id
}

output "staging_dir" {
  description = "Directory on the host that the bootstrap creates for roles to upload files to"
  value       = local.staging_dir
  depends_on  = [null_resource.bootstrap]
}
