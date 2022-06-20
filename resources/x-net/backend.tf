terraform {
  backend "remote" {
    hostname      = "app.terraform.io"
    organization  = "subspace-sre"

    workspaces {
      name = "x-net"
    }
  }
}
