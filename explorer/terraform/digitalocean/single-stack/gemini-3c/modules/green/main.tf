module "green" {
  source          = "../../base/"
  path-to-scripts = "../../base/scripts"
  path-to-configs = "../../base/config"
  network-name    = var.network_name
  deployment-color = var.deployment_color

  squid-node-config = {
    deployment-color   = var.deployment_color
    network-name       = "${var.network_name}-${var.deployment_color}"
    domain-prefix      = "squid"
    droplet_size       = var.droplet_size
    deployment-version = 1
    regions            = var.regions
    nodes-per-region   = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3c"
    prune              = false
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
    environment        = "production"
  }

  archive-node-config = {
    deployment-color   = var.deployment_color
    network-name       = "${var.network_name}-${var.deployment_color}"
    domain-prefix      = "archive"
    droplet_size       = var.droplet_size
    deployment-version = 1
    regions            = var.regions
    nodes-per-region   = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3c"
    prune              = false
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
    environment        = "production"
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key

}
