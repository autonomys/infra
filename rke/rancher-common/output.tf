# Outputs

output "rancher_url" {
  value = "https://${var.rancher_server_dns}"
}

output "custom_cluster_command" {
  value       = rancher2_cluster_v2.subspace_workload.cluster_registration_token.0.insecure_node_command
  description = "Docker command used to add a node to the subspace cluster"
}

output "rancher_admin_password" {
  description = "Password for Rancher 'admin' user"
  value       = random_password.rancher_admin_pasword.result
  sensitive   = true
}

output "rancher_admin_token" {
  description = "API Token for Rancher 'admin' user"
  value       = rancher2_bootstrap.admin.token
}
