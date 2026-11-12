output "host_ipv4" {
  value = var.host.ipv4
}

output "hostname" {
  value = var.host.hostname
}

output "deploy_dir" {
  value = local.deploy_dir
}

output "mesh_address" {
  description = "Where the other mesh members reach Postgres (5432) and RabbitMQ (5672)"
  value       = var.mesh.address
}
