module "devnet" {
  source          = "../../network-primitives"
  path-to-scripts = "../../network-primitives/scripts"
  network-name    = "devnet"
  bootstrap-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 0
    regions             = ["ams3"]
    nodes-per-region    = 0
    additional-node-ips = var.bootstrap_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3d-2023-may-23"
    reserved-only       = false
    prune               = true
    genesis-hash        = ""
    dsn-listen-port     = 50000
    node-dsn-port       = 30433
  }
  full-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 0
    regions             = ["sfo3"]
    nodes-per-region    = 0
    additional-node-ips = var.full_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3d-2023-may-23"
    reserved-only       = false
    prune               = true
    node-dsn-port       = 30433
  }
  rpc-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 0
    regions             = ["fra1"]
    nodes-per-region    = 0
    additional-node-ips = var.rpc_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3d-2023-may-23"
    domain-prefix       = "rpc"
    reserved-only       = false
    prune               = true
    node-dsn-port       = 30433
  }

  domain-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 0
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.domain_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3d-2023-may-23"
    domain-prefix       = "eu"
    reserved-only       = false
    prune               = true
    node-dsn-port       = 30434
    enable-domains      = true
    domain-id           = var.domain_id
    domain-labels       = var.domain_labels
  }

  farmer-node-config = {
    droplet_size           = var.droplet-size
    deployment-version     = 0
    regions                = ["blr1"]
    nodes-per-region       = 0
    additional-node-ips    = var.farmer_node_ips
    docker-org             = "subspace"
    docker-tag             = "gemini-3d-2023-may-23"
    reserved-only          = false
    prune                  = true
    plot-size              = "10G"
    reward-address         = var.farmer-reward-address
    force-block-production = true
    node-dsn-port          = 30433

  }
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key
}
