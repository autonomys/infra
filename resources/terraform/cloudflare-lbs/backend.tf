terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "cloudflare-load-balancers"
    }
  }
}
