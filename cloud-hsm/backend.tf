terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "cloudhsm-v2"
    }
  }
}
