terraform {
  cloud {
    organization = "subspace-sre"

    workspaces {
      name = "vault-manager-eks-prod"
    }
  }
}
