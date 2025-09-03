module "chronos" {
  source                 = "../../../modules/network-primitives"
  path_to_scripts        = "../../../templates/scripts"
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

  consensus-bootstrap-node-config = {
    instance-type    = "c7a.2xlarge"
    genesis-hash     = "91912b429ce7bf2975440a0920b46a892fddeeaed6ccc11c93f2d57ad1bd69ab"
    disk-volume-size = var.disk_volume_size
    disk-volume-type = var.disk_volume_type
    bootstrap-nodes = [
      {
        docker-tag    = "chronos"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
      },
      {
        docker-tag    = "chronos"
        reserved-only = false
        index         = 1
        sync-mode     = "full"
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
        docker-tag    = "chronos"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
      },
      {
        docker-tag    = "chronos"
        reserved-only = false
        index         = 1
        sync-mode     = "full"
      }
    ]
  }

  farmer-node-config = {
    instance-type = "c6id.4xlarge"
    farmer-nodes = [
      {
        docker-tag             = "chronos"
        reserved-only          = false
        plot-size              = "50G"
        reward-address         = "sucqjUNjJBYALeKNnhhwLAkW6zuvTFVnAzhaTgjK6B1gqfNyo"
        cache-percentage       = 50
        force-block-production = true
        faster-sector-plotting = false
        index                  = 0
        sync-mode              = "full"
        is-timekeeper          = true
      }
    ]
  }

  timekeeper-node-config = {
    timekeeper-nodes = [
      {
        docker-tag    = "chronos"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
        ipv4          = var.timekeeper_node_ipv4.timekeeper-0
      }
    ]
  }
}
