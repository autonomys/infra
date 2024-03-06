terraform {
  required_version = ">= 1.5.7"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.7.1"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_secrets.api_token
}
