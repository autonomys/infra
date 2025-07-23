module "devnet" {
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
    docker-tag         = "versioned_bundle"
    reserved-only      = false
    genesis-hash       = "4d5fe311c169ac8f090de6e44fa0dce2ed2c116ffdb475139896f645fc32cccf"
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
    docker-tag         = "versioned_bundle"
    reserved-only      = false
    genesis-hash       = "4d5fe311c169ac8f090de6e44fa0dce2ed2c116ffdb475139896f645fc32cccf"
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
    docker-tag         = "versioned_bundle"
    reserved-only      = false
    genesis-hash       = "4d5fe311c169ac8f090de6e44fa0dce2ed2c116ffdb475139896f645fc32cccf"
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
    docker-tag         = "versioned_bundle"
    domain-prefix      = "rpc-indexer"
    reserved-only      = false
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  auto-evm-indexer-node-config = {
    instance-type      = var.instance_type["auto-evm-indexer"]
    deployment-version = 0
    regions            = var.aws_region
    instance-count     = var.instance_count["auto-evm-indexer"]
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    domain-prefix      = "auto-evm-indexer"
    reserved-only      = false
    node-dsn-port      = 30433
    domain-id          = 0
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
    docker-tag         = "versioned_bundle"
    domain-prefix      = "rpc"
    reserved-only      = false
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  auto-evm-domain-node-config = {
    instance-type      = var.instance_type["auto-evm"]
    deployment-version = 0
    regions            = var.aws_region
    instance-count     = var.instance_count["auto-evm"]
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    domain-prefix      = "auto-evm"
    reserved-only      = false
    node-dsn-port      = 30433
    domain-id          = 0
    domain-labels      = var.domain_labels
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  auto-id-domain-node-config = {
    instance-type      = var.instance_type["auto-id"]
    deployment-version = 0
    regions            = var.aws_region
    instance-count     = var.instance_count["auto-id"]
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    domain-prefix      = "autoid"
    reserved-only      = false
    node-dsn-port      = 30433
    domain-id          = 1
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
    docker-tag             = "versioned_bundle"
    reserved-only          = false
    plot-size              = "2G"
    reward-address         = var.farmer_reward_address
    cache-percentage       = var.cache_percentage
    thread-pool-size       = var.thread_pool_size
    force-block-production = true
    node-dsn-port          = 30433
    disk-volume-size       = var.disk_volume_size
    disk-volume-type       = var.disk_volume_type
    faster-sector-plotting = true
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_zone_id   = var.cloudflare_zone_id
  nr_api_key           = var.nr_api_key
  access_key           = var.access_key
  secret_key           = var.secret_key
  aws_region           = var.aws_region
  azs                  = var.azs
  vpc_id               = var.vpc_id
  instance_type        = var.instance_type
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  aws_key_name         = var.aws_key_name
  ssh_agent_identity   = var.ssh_agent_identity
}
