terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "mainnet-chain-indexer"
    }
  }
}
