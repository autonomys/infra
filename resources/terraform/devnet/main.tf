module "devnet" {
  source                 = "../../../modules/network-primitives"
  path_to_scripts        = "../../../templates/scripts"
  network_name           = "devnet"
  vpc_id                 = "devnet-vpc"
  vpc_cidr_block         = "172.31.0.0/16"
  public_subnet_cidrs    = ["172.31.1.0/24"]
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

  consensus-bootstrap-node-config = {
    instance-type    = "m6a.xlarge"
    genesis-hash     = "79d5a50059ea893fa76d59dac27af5352ae64c989ede77a31464df7ce0c24836"
    disk-volume-size = var.disk_volume_size
    disk-volume-type = var.disk_volume_type
    bootstrap-nodes = [
      {
        docker-tag    = "update-devnet-spec"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
      }
    ]
  }

  consensus-rpc-node-config = {
    instance-type        = "m6a.xlarge"
    dns-prefix           = "rpc"
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    enable-reverse-proxy = true
    enable-load-balancer = true
    rpc-nodes = [
      {
        docker-tag    = "update-devnet-spec"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
      }
    ]
  }

  farmer-node-config = {
    instance-type = "c6id.2xlarge"
    farmer-nodes = [
      {
        docker-tag             = "update-devnet-spec"
        reserved-only          = false
        plot-size              = "2G"
        reward-address         = "sufsKsx4kZ26i7bJXc1TFguysVzjkzsDtE2VDiCEBY2WjyGAj"
        cache-percentage       = 50
        force-block-production = true
        faster-sector-plotting = true
        index                  = 0
        sync-mode              = "full"
      }
    ]
  }

  domain-bootstrap-node-config = {
    instance-type    = "m6a.xlarge"
    disk-volume-size = var.disk_volume_size
    disk-volume-type = var.disk_volume_type
    bootstrap-nodes = [
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "update-devnet-spec"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
      }
    ]
  }

  domain-rpc-node-config = {
    instance-type        = "m6a.xlarge"
    disk-volume-size     = var.disk_volume_size
    disk-volume-type     = var.disk_volume_type
    enable-reverse-proxy = true
    enable-load-balancer = true
    rpc-nodes = [
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "update-devnet-spec"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
        eth-cache     = true
      }
    ]
  }

  domain-operator-node-config = {
    instance-type    = "m6a.xlarge"
    disk-volume-size = var.disk_volume_size
    disk-volume-type = var.disk_volume_type
    operator-nodes = [
      {
        domain-id     = 0
        domain-name   = "auto-evm"
        docker-tag    = "update-devnet-spec"
        reserved-only = false
        index         = 0
        operator-id   = 0
        sync-mode     = "full"
      }
    ]
  }
}
