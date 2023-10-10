// ## Subspace.network zone ##
data "cloudflare_zone" "subspace_network" {
  name = "subspace.network"
}

// ## Subspace.net zone ##
data "cloudflare_zone" "subspace_net" {
  name = "subspace.net"
}

// ## continuim.cc zone ##
data "cloudflare_zone" "continuim_cc" {
  name = "continuim.cc"
}
