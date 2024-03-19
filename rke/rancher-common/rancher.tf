# Rancher resources

resource "random_password" "rancher_admin_pasword" {
  length           = 16
  upper            = true
  min_upper        = 1
  lower            = true
  min_lower        = 1
  numeric          = true
  min_numeric      = 1
  special          = true
  min_special      = 1
  override_special = "_%@"
}

# Initialize Rancher server
resource "rancher2_bootstrap" "admin" {
  depends_on = [
    helm_release.rancher_server
  ]

  provider = rancher2.bootstrap

  password  = random_password.rancher_admin_pasword.result
  telemetry = true
}

# Create custom managed cluster for subspace
resource "rancher2_cluster_v2" "subspace_workload" {
  provider = rancher2.admin

  name               = var.workload_cluster_name
  kubernetes_version = var.workload_kubernetes_version
}
