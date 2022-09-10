terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "gemini-2a"
    }
  }
}
