module "squid-archive-node" {
  source          = "../base/"
  path-to-scripts = "../base/scripts"

  squid-archive-node-config = {
    deployment-color   = var.deployment_color
    network-name       = "gemini-3d-${var.deployment_color}"
    domain-prefix      = string
    droplet_size       = var.droplet_size
    deployment-version = 1
    regions            = var.regions
    nodes-per-region   = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3d"
    #  disk_volume_size            = var.disk_volume_size
    #  disk_volume_type            = var.disk_volume_type
    environment = "staging"
  }

  global-node-config = {
    cloudflare_api_token = var.cloudflare_api_token
    cloudflare_email     = var.cloudflare_email
    do_token             = var.do_token
    ssh_identity         = var.ssh_identity
    datadog_api_key      = var.datadog_api_key
  }


}
