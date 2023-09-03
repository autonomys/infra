# todo: check if A records exists already before creating resources
# rpc node
resource "cloudflare_record" "rpc-0" {
  zone_id = var.zone_id
  name    = "rpc"
  value   = "198.51.100.15"
  type    = "A"
  proxied = true
  tags    = ["rpc", "us"]
}

# rpc node
resource "cloudflare_record" "rpc-1" {
  zone_id = var.zone_id
  name    = "rpc"
  value   = "198.51.100.15"
  type    = "A"
  proxied = true
  tags    = ["rpc", "eu"]
}

# todo: check if A records exists already before creating resources
# EVM domain node
resource "cloudflare_record" "evm-0" {
  zone_id = var.zone_id
  name    = "domain-3"
  value   = "198.51.100.15"
  type    = "A"
  proxied = true
  tags    = ["domain", "evm", "us"]
}

# EVM domain node
resource "cloudflare_record" "evm-1" {
  zone_id = var.zone_id
  name    = "domain-3"
  value   = "198.51.100.15"
  type    = "A"
  proxied = true
  tags    = ["domain", "evm", "eu"]
}

# todo: check expected body, expected codes, and method POST or GET
# health check monitor RPC
resource "cloudflare_load_balancer_monitor" "check-rpc-https" {
  account_id     = var.account_id
  expected_body  = "alive"
  expected_codes = "200"
  method         = "GET"
  timeout        = 5
  path           = "/http"
  interval       = 60
  retries        = 2
  description    = "GET / over HTTPS - expect 200"
}

# health check monitor EVM domain
resource "cloudflare_load_balancer_monitor" "check-evm-https" {
  account_id     = var.account_id
  expected_body  = "alive"
  expected_codes = "200"
  method         = "GET"
  timeout        = 5
  path           = "/http"
  interval       = 60
  retries        = 2
  description    = "GET / over HTTPS - expect 200"
}

# create the pool of origins for rpc nodes
resource "cloudflare_load_balancer_pool" "rpc-nodes" {
  account_id = var.account_id
  name       = "rpc-nodes"
  monitor    = cloudflare_load_balancer_monitor.check-rpc-https.id
  origins {
    name    = "rpc-0"
    address = "203.0.113.10"
  }
  origins {
    name    = "rpc-1"
    address = "198.51.100.15"
  }
  description        = "rpc origins"
  enabled            = true
  minimum_origins    = 1
  steering_policy    = "dynamic_latency"
  notification_email = "alerts@subspace.network"
  check_regions      = ["WNAM", "ENAM", "WEU", "EEU", "SEAS", "NEAS"]
}

# create the pool of origins for domain evm nodes
resource "cloudflare_load_balancer_pool" "evm-nodes" {
  account_id = var.account_id
  name       = "evm-nodes"
  monitor    = cloudflare_load_balancer_monitor.check-evm-https.id
  origins {
    name    = "evm-0"
    address = "203.0.113.10"
  }
  origins {
    name    = "evm-1"
    address = "198.51.100.15"
  }
  description        = "domain evm origins"
  enabled            = true
  minimum_origins    = 1
  steering_policy    = "dynamic_latency"
  notification_email = "alerts@subspace.network"
  check_regions      = ["WNAM", "ENAM", "WEU", "EEU", "SEAS", "NEAS"]
}

# create the load balancer for rpc nodes
resource "cloudflare_load_balancer" "rpc-lb" {
  zone_id          = var.zone_id
  name             = "rpc-lb"
  default_pool_ids = [cloudflare_load_balancer_pool.rpc-nodes.id]
  fallback_pool_id = cloudflare_load_balancer_pool.rpc-nodes.id
  description      = "RPC nodes load balancer"
  proxied          = true
}

# create the load balancer for rpc nodes
resource "cloudflare_load_balancer" "evm-lb" {
  zone_id          = var.zone_id
  name             = "evm-lb"
  default_pool_ids = [cloudflare_load_balancer_pool.evm-nodes.id]
  fallback_pool_id = cloudflare_load_balancer_pool.evm-nodes.id
  description      = "EVM domain nodes load balancer"
  proxied          = true
}
