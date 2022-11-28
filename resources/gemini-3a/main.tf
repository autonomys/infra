module "gemini-3a" {
  source          = "../../network-primitives"
  path-to-scripts = "../../network-primitives/scripts"
  network-name    = "gemini-3a"
  bootstrap-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 1
    regions             = ["nyc1", "sfo3", "blr1", "sgp1", "nyc1", "sgp1"]
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_bootstrap_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3a-2022-nov-28"
    reserved-only       = true
  }
  full-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 1
    regions             = ["nyc1", "sfo3", "blr1", "sgp1"]
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_full_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3a-2022-nov-28"
    reserved-only       = true
  }
  rpc-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 1
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_rpc_node_ips
    docker-org          = "subspace"
    docker-tag          = "gemini-3a-2022-nov-28"
    domain-prefix       = "eu"
    reserved-only       = true
  }
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
}
