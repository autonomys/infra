variable "region" {
  type = string
}

variable "az" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "vpc_cidr_block" {
  type = string
}

variable "eks_cluster_name" {
  type    = string
  default = "vault"
}

variable "acm_vault_arn" {
  type = string
}

variable "private_network_config" {
  type = map(object({
    cidr_block               = string
    associated_public_subnet = string
  }))

  default = {
    "private-vault-1" = {
      cidr_block               = "10.0.0.0/23"
      associated_public_subnet = "public-vault-1"
    },
    "private-vault-2" = {
      cidr_block               = "10.0.2.0/23"
      associated_public_subnet = "public-vault-2"
    },
    "private-vault-3" = {
      cidr_block               = "10.0.4.0/23"
      associated_public_subnet = "public-vault-3"
    }
  }
}

locals {
  private_nested_config = flatten([
    for name, config in var.private_network_config : [
      {
        name                     = name
        cidr_block               = config.cidr_block
        associated_public_subnet = config.associated_public_subnet
      }
    ]
  ])
}

variable "public_network_config" {
  type = map(object({
    cidr_block = string
  }))

  default = {
    "public-vault-1" = {
      cidr_block = "10.0.8.0/23"
    },
    "public-vault-2" = {
      cidr_block = "10.0.10.0/23"
    },
    "public-vault-3" = {
      cidr_block = "10.0.12.0/23"
    }
  }
}

locals {
  public_nested_config = flatten([
    for name, config in var.public_network_config : [
      {
        name       = name
        cidr_block = config.cidr_block
      }
    ]
  ])
}

variable "hosted_zone" {
  type        = string
  default     = "eks.subspace.network"
  description = "eks hosted zone"
}

variable "authorized_source_ranges" {
  type        = string
  description = "Addresses or CIDR blocks which are allowed to connect to the Vault IP address. The default behavior is to allow anyone (0.0.0.0/0) access. You should restrict access to external IPs that need to access the Vault cluster."
  default     = "0.0.0.0/0"
}
