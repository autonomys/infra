terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "gemini-3f"
    }
  }
}
