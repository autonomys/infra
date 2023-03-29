module "devnet" {
  source          = "../../network-primitives"
  path-to-scripts = "../../network-primitives/scripts"
  network-name    = "devnet"
  bootstrap-node-config = {
        droplet_size        = var.droplet-size
        deployment-version  = 0
        regions             = ["ams3"]
        nodes-per-region    = 1
        additional-node-ips = []
        docker-org          = "subspace"
        docker-tag          = "snapshot-2023-mar-28"
        reserved-only       = false
        prune               = true
  }
  full-node-config = {
        droplet_size        = var.droplet-size
        deployment-version  = 0
        regions             = ["sfo3"]
        nodes-per-region    = 1
        additional-node-ips = []
        docker-org          = "subspace"
        docker-tag          = "snapshot-2023-mar-28"
        reserved-only       = false
        prune               = true
  }
  rpc-node-config = {
        droplet_size        = var.droplet-size
        deployment-version  = 0
        regions             = ["fra1"]
        nodes-per-region    = 1
        additional-node-ips = []
        docker-org          = "subspace"
        docker-tag          = "snapshot-2023-mar-28"
        domain-prefix       = "rpc"
        reserved-only       = false
        prune               = true
  }

  farmer-node-config = {
        droplet_size           = var.droplet-size
        deployment-version     = 0
        regions                = ["blr1"]
        nodes-per-region       = 1
        additional-node-ips    = []
        docker-org             = "subspace"
        docker-tag             = "snapshot-2023-mar-28"
        reserved-only          = false
        prune                  = true
        plot-size              = "10G"
        reward-address         = var.farmer-reward-address
        force-block-production = true
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key
}
