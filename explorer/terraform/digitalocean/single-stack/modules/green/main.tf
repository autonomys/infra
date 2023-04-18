module "explorer-node" {
  source          = "../../base/"
  path-to-scripts = "../../base/scripts"
  network-name = var.network_name
  explorer-node-config = {
    deployment-color   = var.deployment_color
    network-name       = "${var.network_name}-${var.deployment_color}"
    domain-prefix      = "explorer"
    droplet_size       = var.droplet_size
    deployment-version = 1
    regions            = var.regions
    nodes-per-region   = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3d"
    prune              = false
    #  disk_volume_size            = var.disk_volume_size
    #  disk_volume_type            = var.disk_volume_type
    environment = "staging"
  }

  archive-squid-node-config = {
    deployment-color   = var.deployment_color
    network-name       = "${var.network_name}-${var.deployment_color}"
    domain-prefix      = "archive"
    droplet_size       = var.droplet_size
    deployment-version = 1
    regions            = var.regions
    nodes-per-region   = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3d"
    prune              = false
    #  disk_volume_size            = var.disk_volume_size
    #  disk_volume_type            = var.disk_volume_type
    environment = "staging"
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key

}
