module "devnet" {
  source               = "../../../templates/terraform/network-primitives"
  path_to_scripts      = "../../../templates/scripts"
  path_to_configs      = "../../../templates/configs"
  network_name         = "devnet"
  vpc_id               = "devnet-vpc"
  vpc_cidr_block       = "172.31.0.0/16"
  public_subnet_cidrs  = ["172.31.1.0/24"]
  ssh_user             = "ubuntu"
  aws_region           = "us-east-1"
  availability_zone    = "us-east-1a"
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_zone_id   = var.cloudflare_zone_id
  new_relic_api_key    = var.new_relic_api_key
  aws_access_key       = var.aws_access_key
  aws_secret_key       = var.aws_secret_key
  aws_ssh_key_name     = var.aws_ssh_key_name
  ssh_agent_identity   = var.ssh_agent_identity

  bootstrap-node-config = {
    instance-type      = "m6a.xlarge"
    deployment-version = 3
    instance-count     = 2
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    reserved-only      = false
    genesis-hash       = "4d5fe311c169ac8f090de6e44fa0dce2ed2c116ffdb475139896f645fc32cccf"
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  bootstrap-node-evm-config = {
    instance-type      = "m6a.xlarge"
    deployment-version = 3
    instance-count     = 1
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    reserved-only      = false
    domain-id          = 0
    domain-prefix      = "auto-evm"
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
    domain-id          = 1
    domain-prefix      = "autoid"
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  rpc-node-config = {
    instance-type      = "m6a.xlarge"
    deployment-version = 3
    instance-count     = 1
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    dns-prefix         = "rpc"
    reserved-only      = false
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  auto-evm-domain-node-config = {
    instance-type      = "m6a.xlarge"
    deployment-version = 3
    instance-count     = 1
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    reserved-only      = false
    domain-id          = 0
    operator-id        = 0
    domain-prefix      = "auto-evm"
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  auto-id-domain-node-config = {
    instance-type      = "m6a.xlarge"
    deployment-version = 0
    instance-count     = 0
    docker-org         = "autonomys"
    docker-tag         = "versioned_bundle"
    reserved-only      = false
    domain-id          = 1
    operator-id        = 1
    domain-prefix      = "autoid"
    disk-volume-size   = var.disk_volume_size
    disk-volume-type   = var.disk_volume_type
  }

  farmer-node-config = {
    instance-type          = "c6id.2xlarge"
    deployment-version     = 3
    instance-count         = 1
    docker-org             = "autonomys"
    docker-tag             = "versioned_bundle"
    reserved-only          = false
    plot-size              = "2G"
    reward-address         = "sufsKsx4kZ26i7bJXc1TFguysVzjkzsDtE2VDiCEBY2WjyGAj"
    cache-percentage       = 50
    force-block-production = true
    faster-sector-plotting = true
  }
}
