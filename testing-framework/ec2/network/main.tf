module "network" {
  source          = "../base"
  path_to_scripts = "../base/scripts"
  network_name    = var.network_name

  bootstrap-node-config = {
    instance-type      = var.instance_type
    deployment-version = 1
    regions            = var.aws_region
    instance-count     = var.instance_count["bootstrap"]
    docker-org         = "subspace"
    docker-tag         = "bootstrap-node"
    reserved-only      = false
    prune              = false
    genesis-hash       = ""
    dsn-listen-port    = 30533
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  node-config = {
    instance-type      = var.instance_type
    deployment-version = 1
    regions            = var.aws_region
    instance-count     = var.instance_count["node"]
    docker-org         = "subspace"
    docker-tag         = "subspace-node"
    reserved-only      = false
    prune              = false
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  domain-node-config = {
    instance-type      = var.instance_type
    deployment-version = 1
    regions            = var.aws_region
    instance-count     = var.instance_count["domain"]
    docker-org         = "subspace"
    docker-tag         = "subspace-node"
    domain-prefix      = "domain"
    reserved-only      = false
    prune              = false
    node-dsn-port      = 30434
    enable-domains     = false
    domain-id          = var.domain_id
    domain-labels      = var.domain_labels
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  farmer-node-config = {
    instance-type          = var.instance_type
    deployment-version     = 1
    regions                = var.aws_region
    instance-count         = var.instance_count["farmer"]
    docker-org             = "subspace"
    docker-tag             = "farmer-node"
    reserved-only          = false
    prune                  = false
    plot-size              = "10G"
    reward-address         = var.farmer_reward_address
    force-block-production = false
    node-dsn-port          = 30433
    disk-volume-size       = var.disk_volume_size
    disk-volume-type       = var.disk_volume_type

  }

  access_key          = var.access_key
  secret_key          = var.secret_key
  vpc_id              = var.vpc_id
  instance_type       = var.instance_type
  vpc_cidr_block      = var.vpc_cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
  tf_token            = var.tf_token
  private_key_path    = var.private_key_path
  branch_name         = var.branch_name

}
