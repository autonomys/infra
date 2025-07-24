module "devnet" {
  source               = "../../../templates/terraform/network-primitives"
  path_to_scripts      = "../../../templates/scripts"
  path_to_configs      = "../../../templates/configs"
  network_name         = "devnet"
  vpc_id               = "devnet-vpc"
  vpc_cidr_block       = "172.31.0.0/16"
  public_subnet_cidrs  = ["172.31.1.0/24"]
  ssh_user             = "ubuntu"
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_zone_id   = var.cloudflare_zone_id
  nr_api_key           = var.nr_api_key
  access_key           = var.access_key
  secret_key           = var.secret_key
  aws_key_name         = var.aws_key_name
  ssh_agent_identity   = var.ssh_agent_identity
  aws_region           = var.aws_region
  azs                  = var.azs

  bootstrap-node-config = {
    instance-type      = "m6a.xlarge"
    deployment-version = 0
    instance-count     = 2
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
    instance-type      = "m6a.xlarge"
    deployment-version = 0
    instance-count     = 1
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
    instance-type      = "m6a.xlarge"
    deployment-version = 0
    instance-count     = 0
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

  rpc-node-config = {
    instance-type      = "m6a.xlarge"
    deployment-version = 0
    instance-count     = 1
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    domain-prefix      = "rpc"
    reserved-only      = false
    node-dsn-port      = 30433
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  auto-evm-domain-node-config = {
    instance-type      = "m6a.xlarge"
    deployment-version = 0
    instance-count     = 1
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    domain-prefix      = "auto-evm"
    reserved-only      = false
    node-dsn-port      = 30433
    domain-id          = 0
    domain-labels      = ["auto-evm"]
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  auto-id-domain-node-config = {
    instance-type      = "m6a.xlarge"
    deployment-version = 0
    instance-count     = 0
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    domain-prefix      = "autoid"
    reserved-only      = false
    node-dsn-port      = 30433
    domain-id          = 1
    domain-labels      = ["autoid"]
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  farmer-node-config = {
    instance-type          = "c6id.2xlarge"
    deployment-version     = 0
    instance-count         = 1
    docker-org             = "autonomys"
    docker-tag             = "versioned_bundle"
    reserved-only          = false
    plot-size              = "2G"
    reward-address         = "sufsKsx4kZ26i7bJXc1TFguysVzjkzsDtE2VDiCEBY2WjyGAj"
    cache-percentage       = 50
    thread-pool-size       = 8
    force-block-production = true
    node-dsn-port          = 30433
    disk-volume-size       = var.disk_volume_size
    disk-volume-type       = var.disk_volume_type
    faster-sector-plotting = true
  }
}
