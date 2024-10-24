module "subql" {
  source          = "../../../../templates/terraform/subql/base/"
  path_to_scripts = "../../../../templates/terraform/subql/base/scripts"
  path_to_configs = "../../../../templates/terraform/subql/base/config"
  network_name    = var.network_name

  blue-subql-node-config = {
    deployment-color    = "blue"
    network-name        = "${var.network_name}"
    domain-prefix       = "subql.blue"
    docker-tag          = "latest"
    instance-type       = var.instance_type
    deployment-version  = 0
    regions             = var.aws_region
    instance-count-blue = var.instance_count_blue
    disk-volume-size    = var.disk_volume_size
    disk-volume-type    = var.disk_volume_type
    prune               = false
    environment         = "production"
  }

  green-subql-node-config = {
    deployment-color     = "green"
    network-name         = "${var.network_name}"
    domain-prefix        = "subql.green"
    docker-tag           = "latest"
    instance-type        = var.instance_type
    deployment-version   = 0
    regions              = var.aws_region
    instance-count-green = var.instance_count_green
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    prune                = false
    environment          = "staging"
  }

  nova-blue-subql-node-config = {
    deployment-color    = "blue"
    network-name        = "${var.network_name}"
    domain-prefix       = "nova.blue"
    docker-tag          = "evm-domain"
    instance-type       = var.instance_type
    deployment-version  = 0
    regions             = var.aws_region
    instance-count-blue = var.instance_count_blue
    disk-volume-size    = var.disk_volume_size
    disk-volume-type    = var.disk_volume_type
    prune               = false
    environment         = "production"
  }

  nova-green-subql-node-config = {
    deployment-color     = "green"
    network-name         = "${var.network_name}"
    domain-prefix        = "nova.green"
    docker-tag           = "evm-domain"
    instance-type        = var.instance_type
    deployment-version   = 0
    regions              = var.aws_region
    instance-count-green = 0 #var.instance_count_green
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    prune                = false
    environment          = "staging"
  }

  cloudflare_api_token        = var.cloudflare_api_token
  cloudflare_email            = var.cloudflare_email
  aws_key_name                = var.aws_key_name
  nr_api_key                  = var.nr_api_key
  netdata_token               = var.netdata_token
  access_key                  = var.access_key
  secret_key                  = var.secret_key
  vpc_id                      = var.vpc_id
  vpc_cidr_block              = var.vpc_cidr_block
  public_subnet_cidrs         = var.public_subnet_cidrs
  postgres_password           = var.postgres_password
  prometheus_secret           = var.prometheus_secret
  hasura_graphql_admin_secret = var.hasura_graphql_admin_secret
}
