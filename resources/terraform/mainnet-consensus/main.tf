module "mainnet_consensus" {
  source                 = "../../../modules/network-primitives"
  path_to_scripts        = "../../../templates/scripts"
  network_name           = "mainnet"
  vpc_id                 = "mainnet-consensus-vpc"
  vpc_cidr_block         = "172.32.0.0/16"
  public_subnet_cidrs    = ["172.32.1.0/24"]
  ssh_user               = "ubuntu"
  aws_region             = "us-west-1"
  availability_zone      = "us-west-1a"
  cloudflare_api_token   = var.cloudflare_api_token
  cloudflare_account_id  = var.cloudflare_account_id
  cloudflare_domain_fqdn = "autonomys.xyz"
  new_relic_api_key      = var.new_relic_api_key
  aws_access_key         = var.aws_access_key
  aws_secret_key         = var.aws_secret_key
  aws_ssh_key_name       = var.aws_ssh_key_name
  ssh_agent_identity     = var.ssh_agent_identity
  deployment_name        = "labs"

  bare-consensus-bootstrap-node-config = {
    genesis-hash = "66455a580aabff303720aa83adbe6c44502922251c03ba73686d5245da9e21bd"
    bootstrap-nodes = [
      {
        docker-tag    = "mainnet-2025-aug-20"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
        ipv4          = "65.108.232.59"
      }
    ]
  }

  consensus-rpc-node-config = {
    instance-type        = "m7i.2xlarge"
    dns-prefix           = "rpc"
    enable-reverse-proxy = true
    enable-load-balancer = true
    disk-volume-size     = 1000
    disk-volume-type     = "gp3"
    rpc-nodes = [
      {
        docker-tag    = "mainnet-2025-aug-20"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
      },
    ]
  }
}
