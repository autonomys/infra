terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.55.0"
    }
  }
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.aws_region[0]
  default_tags {
    tags = {
      Environment = "${var.vpc_id}-testing"
      Owner       = "subspace"
      Project     = "Subspace Network"
    }
  }
}

provider "tfe" {
  token = var.tf_token
}
