output "deploy_dir" {
  value = local.deploy_dir
}

output "deploy_id" {
  description = "Changes whenever the deploy runs"
  value       = null_resource.deploy.id
}

output "ports" {
  description = "Host ports the node and the farmer publish on every interface, all TCP"
  value       = var.ports
}
