module "monitoring" {
  source = "../../../modules/monitoring-host"

  deployer = {
    ssh_user           = "ubuntu"
    ssh_agent_identity = var.ssh_agent_identity
    path_to_scripts    = "../../../scripts"
  }

  instance = {
    ipv4           = var.host_ipv4
    hostname       = "monitoring-loki"
    loki_domain    = "logging.subspace.network"
    grafana_domain = "grafana.subspace.network"
  }

  letsencrypt_email = var.letsencrypt_email

  grafana_admin = {
    user     = var.grafana_admin_user
    password = var.grafana_admin_password
  }
}
