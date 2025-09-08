# Cloudflare Provider Configuration
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}


# =============================================================================
# MONITORS (Import these first)
# =============================================================================

# Monitor 1: RPC Mainnet Health Check
resource "cloudflare_load_balancer_monitor" "rpc_mainnet_health_check" {
  account_id  = var.cloudflare_account_id
  type        = "tcp"
  port        = 30333
  interval    = 60
  retries     = 2
  timeout     = 5
  method      = "connection_established"
  description = "RPC Mainnet Health Check"
}

# =============================================================================
# POOLS (Import these second)
# =============================================================================

# Pool 1: Mainnet-RPC
resource "cloudflare_load_balancer_pool" "mainnet_rpc" {
  account_id      = var.cloudflare_account_id
  name            = "Mainnet-RPC"
  description     = "Mainnet RPC"
  enabled         = true
  minimum_origins = 2
  monitor         = cloudflare_load_balancer_monitor.rpc_mainnet_health_check.id
  check_regions   = ["ENAM"]

  origins {
    name    = "rpc-0.mainnet"
    address = "3.15.239.60"
    enabled = true
    weight  = 0.5
  }

  origins {
    name    = "rpc-1.mainnet"
    address = "3.148.174.0"
    enabled = true
    weight  = 0.5
  }

}

# =============================================================================
# LOAD BALANCERS (Import these last)
# =============================================================================

# Load Balancer 2: rpc-lb.mainnet.autonomys.xyz
resource "cloudflare_load_balancer" "rpc_lb_mainnet" {
  zone_id          = var.cloudflare_zone_id
  name             = "rpc-lb.mainnet.autonomys.xyz"
  description      = "Mainnet RPC consensus load-balancer"
  proxied          = true
  enabled          = true
  session_affinity = "none"
  steering_policy  = "random"
  fallback_pool_id = cloudflare_load_balancer_pool.mainnet_rpc.id

  default_pool_ids = [
    cloudflare_load_balancer_pool.mainnet_rpc.id
  ]

  session_affinity_attributes {
    samesite               = "Auto"
    secure                 = "Auto"
    drain_duration         = 0
    zero_downtime_failover = "none"
  }

  adaptive_routing {
    failover_across_pools = false
  }

  random_steering {
    default_weight = 1
  }

  location_strategy {
    prefer_ecs = "proximity"
    mode       = "pop"
  }

}
