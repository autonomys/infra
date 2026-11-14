locals {
  images = {
    vmagent           = "victoriametrics/vmagent:v1.155.0"
    node_exporter     = "prom/node-exporter:v1.12.1"
    smartctl_exporter = "prometheuscommunity/smartctl-exporter:v0.15.0"
    python            = "python:3.13.18-alpine3.24"
  }

  loki_url     = "https://logging.subspace.network/loki/api/v1/push"
  vmetrics_url = "https://vmetrics.subspace.network/api/v1/write"

  # One entry per server running the agent. The name becomes the host label on
  # its metrics. The server's address and host key go under the same name in
  # common.auto.tfvars: scanners index SSH host keys, so a published key would
  # give the server's address away.
  agents = {
    "auto-drive-files-gateway-chronos" = {
      ssh_user     = "ubuntu"
      disks        = 2
      scrape_ports = {}
    }
    "auto-drive-staging-services" = {
      ssh_user     = "ubuntu"
      disks        = 2
      scrape_ports = {}
    }
    "auto-drive-staging-public" = {
      ssh_user     = "ubuntu"
      disks        = 2
      scrape_ports = {}
    }
  }
}

module "host_agent" {
  source   = "../../../modules/host-agent"
  for_each = local.agents

  deployer = {
    ssh_user           = each.value.ssh_user
    ssh_agent_identity = var.ssh_agent_identity
    path_to_scripts    = "../../../scripts"
  }

  host = {
    name         = each.key
    host_key     = var.servers[each.key].host_key
    disks        = each.value.disks
    scrape_ports = each.value.scrape_ports
  }
  ipv4 = var.servers[each.key].ipv4

  images              = local.images
  loki_url            = local.loki_url
  vmetrics_url        = local.vmetrics_url
  vmetrics_credential = { username = var.vmetrics_fleet_username, password = var.vmetrics_fleet_password }
}
