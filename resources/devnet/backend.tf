terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "devnet-hetzner"
    }
  }
}
