output "host_ipv4" {
  value = var.host.ipv4
}

output "hostname" {
  value = var.host.hostname
}

output "deploy_dir" {
  value = local.deploy_dir
}

output "file_retriever_url" {
  description = "Where the other mesh members reach the file retriever (FILES_GATEWAY_URL), or null without a mesh"
  value       = var.mesh == null ? null : "http://${var.mesh.address}:8090"
}

output "backup_dir" {
  description = "Where the gateway host keeps the gateway database's dumps and their progress floor, or null without dag_indexer"
  value       = var.dag_indexer == null ? null : local.backup_dir
}

output "object_mapping_url" {
  description = "Where the other mesh members reach the object-mapping indexer's WebSocket (OBJECT_MAPPING_ARCHIVER_URL), or null without a mesh"
  value       = var.mesh == null ? null : "ws://${var.mesh.address}:3000/ws"
}

output "deploy_id" {
  description = "Changes whenever this host's deploy runs; another role on this host orders its own deploy after it, so their image pulls and prunes don't overlap"
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
