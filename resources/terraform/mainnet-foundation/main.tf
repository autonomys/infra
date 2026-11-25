module "mainnet_foundation" {
  source                 = "../../../modules/network-primitives"
  path_to_scripts        = "../../../scripts"
  network_name           = "mainnet"
  ssh_user               = "ubuntu"
  aws_region             = "us-west-1"
  cloudflare_api_token   = var.cloudflare_api_token
  cloudflare_account_id  = var.cloudflare_account_id
  cloudflare_domain_fqdn = "subspace.foundation"
  aws_access_key         = var.aws_access_key
  aws_secret_key         = var.aws_secret_key
  ssh_agent_identity     = var.ssh_agent_identity
  deployment_name        = "foundation"

  bare-consensus-bootstrap-node-config = {
    genesis-hash = "66455a580aabff303720aa83adbe6c44502922251c03ba73686d5245da9e21bd"
    bootstrap-nodes = [
      {
        docker-tag    = "mainnet-2026-11-25"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
        ipv4          = "173.208.0.26"
      }
    ]
  }

  bare-consensus-rpc-node-config = {
    dns-prefix           = "rpc"
    enable-reverse-proxy = true
    enable-load-balancer = true
    rpc-nodes = [
      {
        docker-tag    = "mainnet-2026-11-25"
        reserved-only = false
        index         = 0
        sync-mode     = "full"
        ipv4          = var.consensus_rpc_ipv4.rpc-0
      },
    ]
  }
}
