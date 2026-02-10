module "chronos" {
  source                 = "../../../modules/network-primitives"
  path_to_scripts        = "../../../scripts"
  network_name           = "chronos"
  vpc_id                 = "chronos-vpc"
  vpc_cidr_block         = "172.33.0.0/16"
  public_subnet_cidrs    = ["172.33.1.0/24"]
  ssh_user               = "ubuntu"
  aws_region             = "us-east-2"
  availability_zone      = "us-east-2a"
  cloudflare_api_token   = var.cloudflare_api_token
  cloudflare_account_id  = var.cloudflare_account_id
  cloudflare_domain_fqdn = "autonomys.xyz"
  new_relic_api_key      = var.new_relic_api_key
  aws_access_key         = var.aws_access_key
  aws_secret_key         = var.aws_secret_key
  aws_ssh_key_name       = var.aws_ssh_key_name
  ssh_agent_identity     = var.ssh_agent_identity

  bare-consensus-bootstrap-node-config = {
    genesis-hash = "91912b429ce7bf2975440a0920b46a892fddeeaed6ccc11c93f2d57ad1bd69ab"
    bootstrap-nodes = [
      {
        docker-tag    = "chronos-2026-jan-15"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
        ipv4          = "65.108.232.15"
      }
    ]
  }

  consensus-rpc-node-config = {
    instance-type        = "c7a.4xlarge"
    dns-prefix           = "rpc"
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    enable-reverse-proxy = true
    enable-load-balancer = true
    rpc-nodes = [
      {
        docker-tag    = "chronos-2026-jan-15"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
      },
    ]
  }

  timekeeper-node-config = {
    timekeeper-nodes = [
      {
        docker-tag    = "chronos-2026-jan-15"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
        ipv4          = var.timekeeper_node_ipv4.timekeeper-0
        cpu-cores     = "8-11"
      }
    ]
  }

  domain-bootstrap-node-config = {
    instance-type    = "c7a.2xlarge"
    disk-volume-size = var.disk_volume_size
    disk-volume-type = var.disk_volume_type
    bootstrap-nodes = [
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "chronos-2026-jan-15"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
      },
    ]
  }

  domain-rpc-node-config = {
    instance-type        = "c7a.4xlarge"
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    enable-reverse-proxy = true
    enable-load-balancer = true
    rpc-nodes = [
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "chronos-2026-jan-15"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
        eth-cache     = true
      },
    ]
  }

  domain-operator-node-config = {
    instance-type    = "c7a.2xlarge"
    disk-volume-size = var.disk_volume_size
    disk-volume-type = var.disk_volume_type
    operator-nodes = [
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "chronos-2026-jan-15"
        reserved-only = false
        index         = 0
        operator-id   = 0
        sync-mode     = "full"
      },
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "chronos-2026-jan-15"
        reserved-only = false
        index         = 1
        operator-id   = 1
        sync-mode     = "full"
      }
    ]
  }
}
