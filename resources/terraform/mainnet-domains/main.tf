module "mainnet_domains" {
  source                 = "../../../modules/network-primitives"
  path_to_scripts        = "../../../templates/scripts"
  network_name           = "mainnet"
  vpc_id                 = "mainnet-domains-vpc"
  vpc_cidr_block         = "172.32.0.0/16"
  public_subnet_cidrs    = ["172.32.1.0/24"]
  ssh_user               = "ubuntu"
  aws_region             = "us-east-1"
  availability_zone      = "us-east-1a"
  cloudflare_api_token   = var.cloudflare_api_token
  cloudflare_account_id  = var.cloudflare_account_id
  cloudflare_domain_fqdn = "autonomys.xyz"
  new_relic_api_key      = var.new_relic_api_key
  aws_access_key         = var.aws_access_key
  aws_secret_key         = var.aws_secret_key
  aws_ssh_key_name       = var.aws_ssh_key_name
  ssh_agent_identity     = var.ssh_agent_identity

  domain-bootstrap-node-config = {
    instance-type    = "c7a.2xlarge"
    disk-volume-size = 300
    disk-volume-type = var.disk_volume_type
    bootstrap-nodes = [
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "mainnet-2025-aug-1"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
      },
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "mainnet-2025-aug-1"
        reserved-only = false
        index         = 1
        sync-mode     = "full"
      }
    ]
  }

  domain-rpc-node-config = {
    instance-type        = "c7a.4xlarge"
    disk-volume-size     = 500
    disk-volume-type     = var.disk_volume_type
    enable-reverse-proxy = true
    enable-load-balancer = true
    rpc-nodes = [
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "mainnet-2025-aug-1"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
        eth-cache     = true
      },
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "mainnet-2025-aug-1"
        reserved-only = false
        index         = 1
        sync-mode     = "full"
        eth-cache     = true
      }
    ]
  }

  domain-operator-node-config = {
    instance-type    = "c7a.2xlarge"
    disk-volume-size = 300
    disk-volume-type = var.disk_volume_type
    operator-nodes = [
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "mainnet-2025-aug-1"
        reserved-only = false
        index         = 0
        operator-id   = 0
        sync-mode     = "full"
      },
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "mainnet-2025-aug-1"
        reserved-only = false
        index         = 1
        operator-id   = 1
        sync-mode     = "full"
      }
    ]
  }

  bare-domain-operator-node-config = {
    operator-nodes = [
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "mainnet-2025-aug-20"
        reserved-only = false
        index         = 2
        operator-id   = 2
        sync-mode     = "snap"
        ipv4          = "173.208.0.24"
      }
    ]
  }
}
