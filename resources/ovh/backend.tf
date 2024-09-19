terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = var.workspace_name
    }
  }
}
