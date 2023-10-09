terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "ephemeral-devnet"
    }
  }
}
