terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "auto-kol-memory"
    }
  }
}
