terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "mainnet-reward-distributor"
    }
  }
}
