terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "subsquid-explorer"
    }
  }
}
