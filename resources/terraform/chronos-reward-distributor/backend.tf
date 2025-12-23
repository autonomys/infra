terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "chronos-reward-distributor"
    }
  }
}
