module "gemini-3f" {
  source          = "../network-primitives"
  path_to_scripts = "../network-primitives/scripts"
  network_name    = "gemini-3f"
  bootstrap-node-config = {
    instance-type      = var.instance_type
    deployment-version = 1
    regions            = var.aws_region
    instance-count     = var.instance_count + 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3f-2023-aug-17"
    reserved-only      = true
    prune              = false
    genesis-hash       = ""
    dsn-listen-port    = 30533
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  full-node-config = {
    instance-type      = var.instance_type
    deployment-version = 1
    regions            = var.aws_region
    instance-count     = var.instance_count
    docker-org         = "subspace"
    docker-tag         = "gemini-3f-2023-aug-17"
    reserved-only      = true
    prune              = false
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  rpc-node-config = {
    instance-type      = var.instance_type
    deployment-version = 1
    regions            = var.aws_region
    instance-count     = var.instance_count
    docker-org         = "subspace"
    docker-tag         = "gemini-3f-2023-aug-17"
    domain-prefix      = "rpc"
    reserved-only      = true
    prune              = false
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  domain-node-config = {
    instance-type      = var.instance_type
    deployment-version = 1
    regions            = var.aws_region
    instance-count     = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3f-2023-aug-17"
    domain-prefix      = "domain"
    reserved-only      = true
    prune              = false
    node-dsn-port      = 30434
    enable-domains     = true
    domain-id          = var.domain_id
    domain-labels      = var.domain_labels
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  farmer-node-config = {
    instance-type          = var.instance_type
    deployment-version     = 1
    regions                = var.aws_region
    instance-count         = var.instance_count
    docker-org             = "subspace"
    docker-tag             = "gemini-3f-2023-aug-17"
    reserved-only          = true
    prune                  = false
    plot-size              = "10G"
    reward-address         = var.farmer_reward_address
    force-block-production = true
    node-dsn-port          = 30433
    disk-volume-size       = var.disk_volume_size
    disk-volume-type       = var.disk_volume_type

  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  datadog_api_key      = var.datadog_api_key
  access_key           = var.access_key
  secret_key           = var.secret_key
  vpc_id               = var.vpc_id
  instance_type        = var.instance_type
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs

}
