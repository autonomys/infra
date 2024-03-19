terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.55.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.2.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=3.4.0"
    }
  }
  required_version = ">= 1.4.2"
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token
  region     = var.aws_region
}

provider "random" {}
