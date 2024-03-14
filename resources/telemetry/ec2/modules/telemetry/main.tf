module "telemetry" {
  source          = "../../base/"
  path_to_scripts = "../../base/scripts"
  path_to_configs  = "../../base/config"

  telemetry-subspace-node-config = {
    domain-prefix      = "telemetry"
    instance-type      = var.instance_type
    deployment-version = 1
    regions            = var.aws_region
    instance-count     = var.instance_count
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  access_key           = var.access_key
  secret_key           = var.secret_key
  vpc_id               = var.vpc_id
  instance_type        = var.instance_type
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
}
