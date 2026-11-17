terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "monitoring"
    }
  }
}
