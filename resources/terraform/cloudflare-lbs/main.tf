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

# Monitor 2: RPC Taurus Health Check
resource "cloudflare_load_balancer_monitor" "rpc_taurus_health_check" {
  account_id  = var.cloudflare_account_id
  type        = "tcp"
  port        = 30333
  interval    = 60
  retries     = 2
  timeout     = 5
  method      = "connection_established"
  description = "RPC Taurus Health Check"
}

# Monitor 3: RPC Taurus EVM Health Check
resource "cloudflare_load_balancer_monitor" "rpc_taurus_evm_health_check" {
  account_id  = var.cloudflare_account_id
  type        = "tcp"
  port        = 30333
  interval    = 60
  retries     = 2
  timeout     = 5
  method      = "connection_established"
  description = "RPC Taurus EVM Health Check"
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
    address = "54.82.252.177"
    enabled = true
    weight  = 0.5
  }

  origins {
    name    = "rpc-1.mainnet"
    address = "52.90.85.214"
    enabled = true
    weight  = 0.5
  }

}

# Pool 2: Taurus-RPC
resource "cloudflare_load_balancer_pool" "taurus_rpc" {
  account_id      = var.cloudflare_account_id
  name            = "Taurus-RPC"
  description     = ""
  enabled         = true
  minimum_origins = 2
  monitor         = cloudflare_load_balancer_monitor.rpc_taurus_health_check.id
  check_regions   = ["WEU"]

  origin_steering {
    policy = "random"
  }

  origins {
    name    = "rpc-0-taurus"
    address = "52.91.1.29"
    enabled = true
    weight  = 0.5
  }

  origins {
    name    = "rpc-1-taurus"
    address = "174.129.155.116"
    enabled = true
    weight  = 0.5
  }

}

# Pool 3: Taurus-RPC-EVM
resource "cloudflare_load_balancer_pool" "taurus_rpc_evm" {
  account_id      = var.cloudflare_account_id
  name            = "Taurus-RPC-EVM"
  description     = ""
  enabled         = true
  minimum_origins = 1
  monitor         = cloudflare_load_balancer_monitor.rpc_taurus_evm_health_check.id
  check_regions   = ["WNAM"]

  origin_steering {
    policy = "random"
  }

  origins {
    name    = "auto-evm-1"
    address = "18.234.222.92"
    enabled = true
    weight  = 0.5
  }

  origins {
    name    = "auto-evm-3"
    address = "65.108.232.15"
    enabled = false
    weight  = 0.5
  }

}

# Pool 4: Taurus-RPC-EVM-Fallback
resource "cloudflare_load_balancer_pool" "taurus_rpc_evm_fallback" {
  account_id      = var.cloudflare_account_id
  name            = "Taurus-RPC-EVM-Fallback"
  description     = "Taurus Auto-EVM RPC LB"
  enabled         = true
  minimum_origins = 1
  monitor         = cloudflare_load_balancer_monitor.rpc_taurus_evm_health_check.id
  check_regions   = ["WNAM"]

  origins {
    name    = "auto-evm-0"
    address = "34.238.40.85"
    enabled = true
    weight  = 0.25
  }

  origins {
    name    = "auto-evm-2"
    address = "65.108.232.16"
    enabled = false
    weight  = 0.75
  }

}

# =============================================================================
# LOAD BALANCERS (Import these last)
# =============================================================================

# Load Balancer 1: auto-evm-lb.taurus.autonomys.xyz
resource "cloudflare_load_balancer" "auto_evm_lb_taurus" {
  zone_id          = var.cloudflare_zone_id
  name             = "auto-evm-lb.taurus.autonomys.xyz"
  description      = ""
  proxied          = true
  enabled          = true
  session_affinity = "none"
  steering_policy  = "random"
  fallback_pool_id = cloudflare_load_balancer_pool.taurus_rpc_evm_fallback.id

  default_pool_ids = [
    cloudflare_load_balancer_pool.taurus_rpc_evm.id,
    cloudflare_load_balancer_pool.taurus_rpc_evm_fallback.id
  ]

  session_affinity_attributes {
    samesite               = "Auto"
    secure                 = "Auto"
    drain_duration         = 180
    zero_downtime_failover = "sticky"
  }

  adaptive_routing {
    failover_across_pools = true
  }

  random_steering {
    default_weight = 1
  }

  location_strategy {
    prefer_ecs = "proximity"
    mode       = "pop"
  }

}

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

# Load Balancer 3: rpc-lb.taurus.autonomys.xyz
resource "cloudflare_load_balancer" "rpc_lb_taurus" {
  zone_id              = var.cloudflare_zone_id
  name                 = "rpc-lb.taurus.autonomys.xyz"
  description          = ""
  proxied              = true
  enabled              = true
  session_affinity     = "ip_cookie"
  session_affinity_ttl = 259200
  steering_policy      = "random"
  fallback_pool_id     = cloudflare_load_balancer_pool.taurus_rpc.id

  default_pool_ids = [
    cloudflare_load_balancer_pool.taurus_rpc.id
  ]

  session_affinity_attributes {
    samesite               = "Auto"
    secure                 = "Auto"
    drain_duration         = 3600
    zero_downtime_failover = "sticky"
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
