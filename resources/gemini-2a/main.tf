module "gemini-2a" {
  source          = "../../network-primitives"
  path-to-scripts = "../../network-primitives/scripts"
  network-name    = "gemini-2a"
  bootstrap-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 9
    regions             = ["nyc1", "sfo3", "blr1", "sgp1", "nyc1", "sgp1"]
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_bootstrap_node_ips
    docker-org          = "nazar-pc"
    docker-tag          = "gemini-2a-pre-release"
    reserved-only       = false
    prune               = false
    genesis-hash        = ""
    dsn-listen-port     = 50000
    node-dsn-port       = 30433
  }
  full-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 9
    regions             = ["nyc1", "sfo3", "blr1", "sgp1"]
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_full_node_ips
    docker-org          = "nazar-pc"
    docker-tag          = "gemini-2a-pre-release"
    reserved-only       = false
    prune               = false
    node-dsn-port       = 30433
  }
  rpc-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 9
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_rpc_node_ips
    docker-org          = "nazar-pc"
    docker-tag          = "gemini-2a-pre-release"
    domain-prefix       = "eu"
    reserved-only       = false
    prune               = false
    node-dsn-port       = 30433
    enable-domains      = true
  }
  farmer-node-config = {
    droplet_size           = var.droplet-size
    deployment-version     = 9
    regions                = []
    nodes-per-region       = 0
    additional-node-ips    = []
    docker-org             = "nazar-pc"
    docker-tag             = "gemini-2a-pre-release"
    reserved-only          = false
    prune                  = false
    plot-size              = "5G"
    reward-address         = ""
    force-block-production = false
    node-dsn-port          = 30433
  }
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = ""
}
