output "deploy_dir" {
  value = local.deploy_dir
}

output "url" {
  description = "Where auth answers on the host itself; nginx or the mesh carries it further"
  value       = "http://${var.publish_address}:${var.port}"
}

output "deploy_id" {
  description = "Changes whenever the deploy runs, which applies auth's migrations and starts it"
  value       = null_resource.deploy.id
}
