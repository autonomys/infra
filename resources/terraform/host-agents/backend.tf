terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "host-agents"
    }
  }
}
