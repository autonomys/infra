module "devnet" {
  source          = "../network-primitives"
  path_to_scripts = "../network-primitives/scripts"
  network_name    = "devnet"
  bootstrap-node-config = {
    instance-type       = var.instance_type
    deployment-version  = 0
    regions             = var.aws_region
    instance-count      = var.instance_count
    additional-node-ips = var.bootstrap_node_ips
    docker-org          = "subspace"
    docker-tag          = "snapshot-2023-may-23"
    reserved-only       = false
    prune               = false
    genesis-hash        = ""
    dsn-listen-port     = 50000
    node-dsn-port       = 30433
  }

  full-node-config = {
    instance-type       = var.instance_type
    deployment-version  = 0
    regions             = var.aws_region
    instance-count      = var.instance_count
    additional-node-ips = var.full_node_ips
    docker-org          = "subspace"
    docker-tag          = "snapshot-2023-may-23"
    reserved-only       = false
    prune               = false
    node-dsn-port       = 30433
  }

  rpc-node-config = {
    instance-type       = var.instance_type
    deployment-version  = 0
    regions             = var.aws_region
    instance-count      = var.instance_count
    additional-node-ips = var.rpc_node_ips
    docker-org          = "subspace"
    docker-tag          = "snapshot-2023-may-23"
    domain-prefix       = "rpc"
    reserved-only       = false
    prune               = false
    node-dsn-port       = 30433
  }

  domain-node-config = {
    instance-type       = var.instance_type
    deployment-version  = 0
    regions             = var.aws_region
    instance-count      = var.instance_count
    additional-node-ips = var.domain_node_ips
    docker-org          = "subspace"
    docker-tag          = "snapshot-2023-may-23"
    domain-prefix       = "eu"
    reserved-only       = false
    prune               = false
    node-dsn-port       = 30434
    enable-domains      = true
    domain-id           = var.domain_id
    domain-labels       = var.domain_labels
  }

  farmer-node-config = {
    instance-type          = var.instance_type
    deployment-version     = 0
    regions                = var.aws_region
    instance-count         = var.instance_count
    additional-node-ips    = var.farmer_node_ips
    docker-org             = "subspace"
    docker-tag             = "snapshot-2023-may-23"
    reserved-only          = false
    prune                  = false
    plot-size              = "10G"
    reward-address         = var.farmer_reward_address
    force-block-production = false
    node-dsn-port          = 30433

  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  datadog_api_key      = var.datadog_api_key
  access_key           = var.access_key
  secret_key           = var.secret_key

}
