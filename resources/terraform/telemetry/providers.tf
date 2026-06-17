terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.8"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region

  default_tags {
    tags = {
      Environment = "Telemetry"
      Owner       = "subspace"
      Project     = "Subspace Network Telemetry API"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
