module "gemini-3b" {
  source          = "../../network-primitives"
  path-to-scripts = "../../network-primitives/scripts"
  network-name    = "gemini-3b"
  bootstrap-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 15
    regions             = ["nyc1", "sfo3", "blr1", "sgp1", "nyc1", "sgp1"]
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_bootstrap_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3b-2022-dec-19"
    reserved-only       = false
    prune               = false
  }
  full-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 15
    regions             = ["nyc1", "sfo3", "blr1", "sgp1"]
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_full_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3b-2022-dec-19"
    reserved-only       = false
    prune               = false
  }
  rpc-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 15
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_rpc_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3b-2022-dec-19"
    domain-prefix       = "eu"
    reserved-only       = false
    prune               = false
  }
  farmer-node-config = {
    droplet_size           = var.droplet-size
    deployment-version     = 9
    regions                = []
    nodes-per-region       = 0
    additional-node-ips    = []
    docker-org             = "subspace"
    docker-tag             = "gemini-3b-2022-dec-19"
    reserved-only          = false
    prune                  = false
    plot-size              = "5G"
    reward-address         = ""
    force-block-production = false
  }
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key
}
