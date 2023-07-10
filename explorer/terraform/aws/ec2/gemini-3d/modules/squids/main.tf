module "squids" {
  source           = "../../base/"
  path_to_scripts  = "../../base/scripts"
  path_to_configs  = "../../base/config"
  network_name     = var.network_name

  blue-squid-node-config = {
    deployment-color     = "blue"
    network-name         = "${var.network_name}-blue"
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
    deployment-color     = "green"
    network-name         = "${var.network_name}-green"
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
    network-name         = "${var.network_name}"
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
  vpc_id               = var.vpc_id
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
}
