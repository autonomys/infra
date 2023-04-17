module "explorer-node-blue" {
  source          = "../network"
  path-to-scripts = "../network/scripts"

  explorer-node-config = {
    deployment-color   = "blue"
    network-name       = "gemini-3d-blue"
    droplet_size       = var.droplet_size
    deployment-version = 1
    regions            = ["nyc1"]
    nodes-per-region   = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3d"
    #  disk_volume_size            = var.disk_volume_size
    #  disk_volume_type            = var.disk_volume_type
    environment        = "staging"
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key

}

module "explorer-node-green" {
  source          = "../network"
  path-to-scripts = "../network/scripts"

  explorer-node-config = {
    deployment-color   = "green"
    network-name       = "gemini-3d-green"
    droplet_size       = var.droplet_size
    deployment-version = 1
    regions            = ["nyc1"]
    nodes-per-region   = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3d"
    #  disk_volume_size            = var.disk_volume_size
    #  disk_volume_type            = var.disk_volume_type
    environment        = "production"
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key

}

module "squid-archive-node-blue" {

  source          = "../network"
  path-to-scripts = "../network/scripts"

  squid-archive-node-config = {
    deployment-color   = "blue"
    network-name       = "gemini-3d-blue"
    droplet_size       = var.droplet_size
    deployment-version = 1
    regions            = ["AMS3"]
    nodes-per-region   = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3d"
    #  disk_volume_size            = var.disk_volume_size
    #  disk_volume_type            = var.disk_volume_type
    environment        = "staging"
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key

}

module "squid-archive-node-green" {

  source          = "../network"
  path-to-scripts = "../network/scripts"

  squid-archive-node-config = {
    deployment-color   = "green"
    network-name       = "gemini-3d-green"
    droplet_size       = var.droplet_size
    deployment-version = 1
    regions            = ["AMS3"]
    nodes-per-region   = 1
    docker-org         = "subspace"
    docker-tag         = "gemini-3d"
    #  disk_volume_size            = var.disk_volume_size
    #  disk_volume_type            = var.disk_volume_type
    environment        = "production"
  }

  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_email     = var.cloudflare_email
  do_token             = var.do_token
  ssh_identity         = var.ssh_identity
  datadog_api_key      = var.datadog_api_key

}