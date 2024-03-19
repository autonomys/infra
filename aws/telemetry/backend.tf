terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "telemetry-aws"
    }
  }
}
