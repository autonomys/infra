data "cloudflare_zone" "ai3_storage" {
  filter = {
    name = "ai3.storage"
  }
}

data "cloudflare_zone" "autonomys_net" {
  filter = {
    name = "autonomys.net"
  }
}

data "cloudflare_zone" "autonomys_network" {
  filter = {
    name = "autonomys.network"
  }
}

data "cloudflare_zone" "autonomys_xyz" {
  filter = {
    name = "autonomys.xyz"
  }
}

data "cloudflare_zone" "continuum_co" {
  filter = {
    name = "continuum.co"
  }
}

data "cloudflare_zone" "subspace_foundation" {
  filter = {
    name = "subspace.foundation"
  }
}

data "cloudflare_zone" "subspace_net" {
  filter = {
    name = "subspace.net"
  }
}

data "cloudflare_zone" "subspace_network" {
  filter = {
    name = "subspace.network"
  }
}

locals {
  proxied_data = jsondecode(file("${path.module}/proxied.json"))
}
