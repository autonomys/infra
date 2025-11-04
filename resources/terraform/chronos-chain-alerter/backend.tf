terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "chronos-chain-alerter"
    }
  }
}
