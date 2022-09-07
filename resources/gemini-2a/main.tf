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
    nodes-per-region    = 3
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

moved {
  from = digitalocean_project.gemini-2a
  to   = module.gemini-2a.digitalocean_project.project
}

moved {
  from = null_resource.boostrap-node-keys
  to   = module.gemini-2a.null_resource.boostrap-node-keys[0]
}

moved {
  from = null_resource.setup-bootstrap-nodes
  to   = module.gemini-2a.null_resource.setup-bootstrap-nodes
}

moved {
  from = null_resource.start-boostrap-nodes
  to   = module.gemini-2a.null_resource.start-boostrap-nodes
}

moved {
  from = cloudflare_record.bootstrap
  to   = module.gemini-2a.cloudflare_record.bootstrap
}

moved {
  from = cloudflare_record.rpc
  to   = module.gemini-2a.cloudflare_record.rpc
}

moved {
  from = digitalocean_droplet.gemini-2a-bootstrap-nodes
  to   = module.gemini-2a.digitalocean_droplet.bootstrap-nodes
}

moved {
  from = digitalocean_droplet.gemini-2a-full-nodes
  to   = module.gemini-2a.digitalocean_droplet.full-nodes
}

moved {
  from = digitalocean_firewall.gemini-2a-boostrap-node-firewall
  to   = module.gemini-2a.digitalocean_firewall.boostrap-node-firewall
}

moved {
  from = digitalocean_firewall.gemini-2a-full-node-firewall
  to   = module.gemini-2a.digitalocean_firewall.full-node-firewall
}

moved {
  from = null_resource.full-node-keys
  to   = module.gemini-2a.null_resource.full-node-keys[0]
}

moved {
  from = null_resource.setup-full-nodes
  to   = module.gemini-2a.null_resource.setup-full-nodes
}

moved {
  from = null_resource.start-full-nodes
  to   = module.gemini-2a.null_resource.start-full-nodes
}


moved {
  from = null_resource.rpc-node-keys
  to   = module.gemini-2a.null_resource.rpc-node-keys[0]
}

moved {
  from = null_resource.setup-rpc-nodes
  to   = module.gemini-2a.null_resource.setup-rpc-nodes
}

moved {
  from = null_resource.start-rpc-nodes
  to   = module.gemini-2a.null_resource.start-rpc-nodes
}
