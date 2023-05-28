terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "explorer-gemini-network-aws"
    }
  }
}
