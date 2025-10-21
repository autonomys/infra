terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }

    # TODO: upgrade to 5.9 when available
    # `cloudflare_load_balancer_monitor` is giving out created_on, modified_on, path as changed
    # causing the plan to detect changes and updates-in-place
    # more here https://github.com/cloudflare/terraform-provider-cloudflare/issues/5676
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.8.2"
    }
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
  default_tags {
    tags = {
      Environment = var.network_name
      Owner       = "subspace"
      Project     = "Autonomys network"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
