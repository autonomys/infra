terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "squid-3g-aws"
    }
  }
}
