terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "subql-mainnet-aws"
    }
  }
}
