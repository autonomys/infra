module "subql" {
  source          = "../../../../templates/terraform/subql/base/"
  path_to_scripts = "../../../../templates/terraform/subql/base/scripts"
  path_to_configs = "../../../../templates/terraform/subql/base/config"
  network_name    = var.network_name

  blue-subql-node-config = {
    deployment-color    = "blue"
    network-name        = "${var.network_name}"
    domain-prefix       = "subql.blue"
    docker-tag          = "taurus-2024-oct-30"
    instance-type       = var.instance_type
    deployment-version  = 0
    regions             = var.aws_region
    instance-count-blue = var.instance_count_blue
    disk-volume-size    = var.disk_volume_size
    disk-volume-type    = var.disk_volume_type
    environment         = "production"
  }

  green-subql-node-config = {
    deployment-color     = "green"
    network-name         = "${var.network_name}"
    domain-prefix        = "subql.green"
    docker-tag           = "taurus-2024-oct-30"
    instance-type        = var.instance_type
    deployment-version   = 0
    regions              = var.aws_region
    instance-count-green = var.instance_count_green
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    environment          = "staging"
  }

  nova-blue-subql-node-config = {
    deployment-color    = "blue"
    network-name        = "${var.network_name}"
    domain-prefix       = "nova.subql.blue"
    docker-tag          = "taurus-2024-oct-30"
    instance-type       = var.instance_type
    deployment-version  = 0
    regions             = var.aws_region
    instance-count-blue = 0 #var.instance_count_blue
    disk-volume-size    = var.disk_volume_size
    disk-volume-type    = var.disk_volume_type
    environment         = "production"
  }

  nova-green-subql-node-config = {
    deployment-color     = "green"
    network-name         = "${var.network_name}"
    domain-prefix        = "nova.subql.green"
    docker-tag           = "taurus-2024-oct-30"
    instance-type        = var.instance_type
    deployment-version   = 0
    regions              = var.aws_region
    instance-count-green = 0 #var.instance_count_green
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    environment          = "staging"
  }

  cloudflare_api_token        = var.cloudflare_api_token
  cloudflare_email            = var.cloudflare_email
  aws_key_name                = var.aws_key_name
  nr_api_key                  = var.nr_api_key
  access_key                  = var.access_key
  secret_key                  = var.secret_key
  vpc_id                      = var.vpc_id
  vpc_cidr_block              = var.vpc_cidr_block
  public_subnet_cidrs         = var.public_subnet_cidrs
  postgres_password           = var.postgres_password
  hasura_graphql_admin_secret = var.hasura_graphql_admin_secret
  hasura_graphql_jwt_secret   = var.hasura_graphql_jwt_secret
}
