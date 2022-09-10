module "gemini-2a" {
  source          = "../../network-primitives"
  path-to-scripts = "../../network-primitives/scripts"
  network-name    = "gemini-2a"
  bootstrap-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 8
    regions             = ["nyc1", "sfo3", "blr1", "sgp1", "nyc1", "sgp1"]
    nodes-per-region    = 1
    additional-node-ips = var.hetzner_bootstrap_node_ips
    docker-org          = "nazar-pc"
    docker-tag          = "gemini-2a-pre-release"
    reserved-only       = false
  }
  full-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 8
    regions             = ["nyc1", "sfo3", "blr1", "sgp1"]
    nodes-per-region    = 2
    additional-node-ips = var.hetzner_full_node_ips
    docker-org          = "nazar-pc"
    docker-tag          = "gemini-2a-pre-release"
    reserved-only       = false
  }
  rpc-node-config = {
    droplet_size        = var.droplet-size
    deployment-version  = 8
    regions             = []
    nodes-per-region    = 0
    additional-node-ips = var.hetzner_rpc_node_ips
    docker-org          = "nazar-pc"
    docker-tag          = "gemini-2a-pre-release"
    domain-prefix       = "eu"
    reserved-only       = false
  }
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
}
