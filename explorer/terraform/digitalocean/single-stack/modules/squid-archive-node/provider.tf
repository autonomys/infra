terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.18.0"
    }
    
    null = {
      source = "hashicorp/null"
    }
    
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }

}


provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Set DigitalOcean as provider
provider "digitalocean" {
  token = var.do_token
}

provider "cloudflare" {
  email     = var.cloudflare_email
  api_token = var.cloudflare_api_token
}
