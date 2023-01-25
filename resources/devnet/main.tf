module "devnet" {
  source          = "../../network-primitives"
  path-to-scripts = "../../network-primitives/scripts"
  network-name    = "devnet"
  bootstrap-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 3
    regions             = ["ams3"]
    nodes-per-region    = 1
    additional-node-ips = []
    docker-org          = "subspace"
    docker-tag          = "snapshot-2023-jan-26"
    reserved-only       = false
    prune               = false
  }
  full-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 3
    regions             = ["sfo3"]
    nodes-per-region    = 1
    additional-node-ips = []
    docker-org          = "subspace"
    docker-tag          = "snapshot-2023-jan-26"
    reserved-only       = false
    prune               = false
  }
  rpc-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 4
    regions             = ["fra1"]
    nodes-per-region    = 1
    additional-node-ips = []
    docker-org          = "subspace"
    docker-tag          = "snapshot-2023-jan-26"
    domain-prefix       = "rpc"
    reserved-only       = false
    prune               = false
  }
  farmer-node-config = {
    droplet_size           = var.droplet-size
    deployment-version     = 5
    regions                = ["blr1"]
    nodes-per-region       = 1
    additional-node-ips    = []
    docker-org             = "subspace"
    docker-tag             = "snapshot-2023-jan-26"
    reserved-only          = false
    prune                  = false
    plot-size              = "10G"
    reward-address         = var.farmer-reward-address
    force-block-production = false
  }
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key
}
