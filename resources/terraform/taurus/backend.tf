terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "taurus"
    }
  }
}
