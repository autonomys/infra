module "gemini-3d" {
  source          = "../../network-primitives"
  path-to-scripts = "../../network-primitives/scripts"
  network-name    = "gemini-3d"
  bootstrap-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 10
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.bootstrap_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3d-2023-may-15"
    reserved-only       = false
    prune               = false
    genesis-hash        = "0x7f489750cfe91e17fc19b42a5acaba41d1975cedd3440075d4a4b4171ad0ac20"
    dsn-listen-port     = 50001
    node-dsn-port       = 30434
  }

  full-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 7
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.full_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3d-2023-may-15"
    reserved-only       = false
    prune               = false
    node-dsn-port       = 30434
  }

  rpc-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 7
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.rpc_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3d-2023-may-15"
    domain-prefix       = "eu"
    reserved-only       = false
    prune               = false
    node-dsn-port       = 30434
  }

  domain-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 1
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.domain_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3d-2023-may-15"
    domain-prefix       = "eu"
    reserved-only       = false
    prune               = false
    node-dsn-port       = 30434
    enable-domains      = true
    domain-id           = var.domain_id
    domain-labels        = var.domain_labels
  }

  farmer-node-config = {
    droplet_size           = var.droplet-size
    deployment-version     = 1
    regions                = []
    nodes-per-region       = 0
    additional-node-ips    = var.farmer_node_ips
    docker-org             = "subspace"
    docker-tag             = "gemini-3d-2023-may-15"
    reserved-only          = false
    plot-size              = "10G"
    reward-address         = var.farmer-reward-address
    force-block-production = false
    prune                  = false
    node-dsn-port          = 30434
  }
  piece_cache_size     = "50G"
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key
}
