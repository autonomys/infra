terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "mainnet-foundation"
    }
  }
}
