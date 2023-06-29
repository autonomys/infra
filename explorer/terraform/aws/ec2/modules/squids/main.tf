module "squids" {
  source           = "../../base/"
  path_to_scripts  = "../../base/scripts"
  path_to_configs  = "../../base/config"
  network_name     = var.network_name
  deployment_color = var.deployment_color

  blue-squid-node-config = {
    deployment-color     = var.deployment_color
    network-name         = "${var.network_name}-${var.deployment_color}"
    domain-prefix        = "evm"
    instance-type        = var.instance_type
    deployment-version   = 0
    regions              = var.aws_region
    instance-count-blue  = var.instance_count_blue
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    prune                = false
    environment          = "staging"
  }

  green-squid-node-config = {
    deployment-color     = var.deployment_color
    network-name         = "${var.network_name}-${var.deployment_color}"
    domain-prefix        = "evm"
    instance-type        = var.instance_type
    deployment-version   = 0
    regions              = var.aws_region
    instance-count-green  = var.instance_count_green
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    prune                = false
    environment          = "production"
  }

  archive-node-config = {
    network-name         = "${var.network_name}-${var.deployment_color}"
    domain-prefix        = "evm"
    instance-type        = var.instance_type
    deployment-version   = 0
    regions              = var.aws_region
    instance-count       = 1
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    prune                = false
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  aws_key_name         = var.aws_key_name
  datadog_api_key      = var.datadog_api_key
  access_key           = var.access_key
  secret_key           = var.secret_key

}
