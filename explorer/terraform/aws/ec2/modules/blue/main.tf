module "blue" {
  source          = "../../base/"
  path_to_scripts = "../../base/scripts"
  path_to_configs = "../../base/config"
  network_name    = var.network_name
  deployment_color = var.deployment_color

  squid-node-config = {
    deployment-color   = var.deployment_color
    network-name       = "${var.network_name}-${var.deployment_color}"
    domain-prefix      = "evm.squid"
    instance-type      = var.instance_type
    deployment-version = 1
    regions            = var.aws_region
    instance-count     = var.instance_count
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
    prune = false
    environment        = "staging"
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  aws_key_name         = var.aws_key_name
  datadog_api_key      = var.datadog_api_key
  access_key           = var.access_key
  secret_key           = var.secret_key

}
