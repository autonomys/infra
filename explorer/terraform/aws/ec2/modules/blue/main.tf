module "blue" {
  source          = "../../base/"
  path-to-scripts = "../../base/scripts"
  path-to-configs = "../../base/config"
  network-name    = var.network_name
  deployment-color = var.deployment_color

  squid-node-config = {
    deployment-color   = var.deployment_color
    network-name       = "${var.network_name}-${var.deployment_color}"
    domain-prefix      = "squid"
    instance-size       = var.instance_size
    deployment-version = 1
    regions            = var.regions
    nodes-per-region   = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3d"
    prune              = false
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
    environment        = "staging"
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  aws_key_name         = var.aws_key_name
  datadog_api_key      = var.datadog_api_key

}
