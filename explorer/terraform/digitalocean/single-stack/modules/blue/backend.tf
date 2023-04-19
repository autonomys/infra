terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "squid-blue"
    }
  }
}
