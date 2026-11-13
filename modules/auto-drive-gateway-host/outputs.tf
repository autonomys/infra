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

output "object_mapping_url" {
  description = "Where the other mesh members reach the object-mapping indexer's WebSocket (OBJECT_MAPPING_ARCHIVER_URL), or null without a mesh"
  value       = var.mesh == null ? null : "ws://${var.mesh.address}:3000/ws"
}
