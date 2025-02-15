module "mainnet" {
  source          = "../../../templates/terraform/network-primitives"
  path_to_scripts = "../../../templates/scripts"
  path_to_configs = "../../../templates/configs"
  network_name    = var.network_name

  bootstrap-node-config = {
    instance-type      = var.instance_type["bootstrap"]
    deployment-version = 0
    regions            = var.aws_region
    instance-count     = var.instance_count["bootstrap"]
    docker-org         = "autonomys"
    docker-tag         = "mainnet-2025-jan-14"
    reserved-only      = false
    prune              = false
    genesis-hash       = "b256e3ca1d3ef43c1e52799df670aa307671b9e468c500def1f5b6b77173b5d4"
    dsn-listen-port    = 30533
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  bootstrap-node-evm-config = {
    instance-type      = var.instance_type["evm_bootstrap"]
    deployment-version = 0
    regions            = var.aws_region
    instance-count     = var.instance_count["evm_bootstrap"]
    docker-org         = "autonomys"
    docker-tag         = "mainnet-2025-jan-14"
    reserved-only      = false
    prune              = false
    genesis-hash       = "b256e3ca1d3ef43c1e52799df670aa307671b9e468c500def1f5b6b77173b5d4"
    dsn-listen-port    = 30533
    node-dsn-port      = 30433
    operator-port      = 30334
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  bootstrap-node-autoid-config = {
    instance-type      = var.instance_type["autoid_bootstrap"]
    deployment-version = 0
    regions            = var.aws_region
    instance-count     = var.instance_count["autoid_bootstrap"]
    docker-org         = "autonomys"
    docker-tag         = "mainnet-2025-jan-14"
    reserved-only      = false
    prune              = false
    genesis-hash       = "b256e3ca1d3ef43c1e52799df670aa307671b9e468c500def1f5b6b77173b5d4"
    dsn-listen-port    = 30533
    node-dsn-port      = 30433
    operator-port      = 30334
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  rpc-indexer-node-config = {
    instance-type      = var.instance_type["rpc-indexer"]
    deployment-version = 0
    regions            = var.aws_region
    instance-count     = var.instance_count["rpc-indexer"]
    docker-org         = "autonomys"
    docker-tag         = "mainnet-2025-jan-14"
    domain-prefix      = "rpc-indexer"
    reserved-only      = false
    prune              = false
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  nova-indexer-node-config = {
    instance-type      = var.instance_type["nova-indexer"]
    deployment-version = 0
    regions            = var.aws_region
    instance-count     = var.instance_count["nova-indexer"]
    docker-org         = "autonomys"
    docker-tag         = "mainnet-2025-jan-14"
    domain-prefix      = "auto-evm-indexer"
    reserved-only      = false
    prune              = false
    node-dsn-port      = 30433
    enable-domains     = true
    domain-id          = var.domain_id
    domain-labels      = var.domain_labels
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  rpc-node-config = {
    instance-type      = var.instance_type["rpc"]
    deployment-version = 0
    regions            = var.aws_region
    instance-count     = var.instance_count["rpc"]
    docker-org         = "autonomys"
    docker-tag         = "mainnet-2025-jan-14"
    domain-prefix      = "rpc"
    reserved-only      = false
    prune              = false
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  domain-node-config = {
    instance-type      = var.instance_type["domain"]
    deployment-version = 0
    regions            = var.aws_region
    instance-count     = var.instance_count["domain"]
    docker-org         = "autonomys"
    docker-tag         = "mainnet-2025-jan-14"
    domain-prefix      = ["auto-evm", "autoid"]
    reserved-only      = false
    prune              = false
    node-dsn-port      = 30433
    enable-domains     = true
    domain-id          = var.domain_id
    domain-labels      = var.domain_labels
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  farmer-node-config = {
    instance-type          = var.instance_type["farmer"]
    deployment-version     = 0
    regions                = var.aws_region
    instance-count         = var.instance_count["farmer"]
    docker-org             = "autonomys"
    docker-tag             = "mainnet-2025-jan-14"
    reserved-only          = false
    prune                  = false
    plot-size              = "10G"
    reward-address         = var.farmer_reward_address
    cache-percentage       = var.cache_percentage
    thread-pool-size       = var.thread_pool_size
    force-block-production = true
    node-dsn-port          = 30433
    disk-volume-size       = var.disk_volume_size
    disk-volume-type       = var.disk_volume_type

  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  nr_api_key           = var.nr_api_key
  access_key           = var.access_key
  secret_key           = var.secret_key
  vpc_id               = var.vpc_id
  instance_type        = var.instance_type
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  pot_external_entropy = var.pot_external_entropy

}
