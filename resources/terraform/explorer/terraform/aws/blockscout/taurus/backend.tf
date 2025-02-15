terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "blockscout"
    }
  }
}
