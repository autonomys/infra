terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}

provider "aws" {
  access_key = var.aws.access_key
  secret_key = var.aws.secret
  region     = var.aws.region
  default_tags {
    tags = {
      Environment = var.instance.network_name
      Owner       = "subspace"
      Project     = "Autonomys network operator reward distributor"
    }
  }
}
