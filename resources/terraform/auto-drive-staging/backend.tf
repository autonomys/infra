terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "auto-drive-staging"
    }
  }
}
