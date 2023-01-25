module "gemini-3c" {
  source          = "../../network-primitives"
  path-to-scripts = "../../network-primitives/scripts"
  network-name    = "gemini-3c"
  bootstrap-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 3
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_bootstrap_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3c-2023-jan-18"
    reserved-only       = false
  }
  full-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 3
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_full_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3c-2023-jan-18"
    reserved-only       = false
  }
  rpc-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 4
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_rpc_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3c-2023-jan-18"
    domain-prefix       = "eu"
    reserved-only       = false
  }
  farmer-node-config = {
    droplet_size           = var.droplet-size
    deployment-version     = 4
    regions                = []
    nodes-per-region       = 0
    additional-node-ips    = []
    docker-org             = "subspace"
    docker-tag             = "gemini-3c-2023-jan-18"
    domain-prefix          = "eu"
    reserved-only          = false
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
