terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "subql-taurus-aws"
    }
  }
}
