# Fetch the record if it exists
data "cloudflare_zones" "subspace" {
  filter {
    name   = var.domain
    status = "active"
  }
}

# rpc node
data "cloudflare_record" "existing_rpc_record" {
  zone_id  = data.cloudflare_zones.subspace.id
  hostname = "rpc.${var.network}.${var.domain}"
  type     = "A"
}

resource "cloudflare_record" "rpc-0" {
  count   = length(data.cloudflare_record.existing_rpc_record.hostname) > 0 ? 0 : 1
  zone_id = var.zone_id
  name    = "rpc"
  value   = "52.91.27.239"
  type    = "A"
  proxied = true
  tags    = ["rpc", "us"]
}

# rpc node
resource "cloudflare_record" "rpc-1" {
  count   = length(data.cloudflare_record.existing_rpc_record.hostname) > 0 ? 0 : 1
  zone_id = var.zone_id
  name    = "rpc"
  value   = "65.108.232.52"
  type    = "A"
  proxied = true
  tags    = ["rpc", "eu"]
}

# EVM domain node
data "cloudflare_record" "existing_domain_record" {
  zone_id  = data.cloudflare_zones.subspace.id
  hostname = "domain-3.${var.network}.${var.domain}"
  type     = "A"
}
resource "cloudflare_record" "evm-0" {
  count   = length(data.cloudflare_record.existing_domain_record.hostname) > 0 ? 0 : 1
  zone_id = var.zone_id
  name    = "domain-3"
  value   = "174.129.202.104"
  type    = "A"
  proxied = true
  tags    = ["domain", "evm", "us"]
}

# EVM domain node
resource "cloudflare_record" "evm-1" {
  count   = length(data.cloudflare_record.existing_domain_record.hostname) > 0 ? 0 : 1
  zone_id = var.zone_id
  name    = "domain-3"
  value   = "65.108.228.84"
  type    = "A"
  proxied = true
  tags    = ["domain", "evm", "eu"]
}


# health check monitor RPC
resource "cloudflare_load_balancer_monitor" "check-rpc-tcp" {
  account_id     = var.account_id
  type           = "tcp"
  expected_codes = "2xx"
  timeout        = 5
  interval       = 60
  retries        = 2
  port           = 30333
  description    = "TCP Check port- expect 2xx"
}

# health check monitor EVM domain
resource "cloudflare_load_balancer_monitor" "check-evm-tcp" {
  account_id     = var.account_id
  type           = "tcp"
  expected_codes = "2xx"
  timeout        = 5
  interval       = 60
  retries        = 2
  port           = 30333
  description    = "TCP Check port- expect 2xx"
}

# create the pool of origins for rpc nodes
resource "cloudflare_load_balancer_pool" "rpc-nodes" {
  account_id = var.account_id
  name       = "rpc-nodes"
  monitor    = cloudflare_load_balancer_monitor.check-rpc-tcp.id
  origins {
    name    = "rpc-0"
    address = "52.91.27.239"
  }
  origins {
    name    = "rpc-1"
    address = "65.108.232.52"
  }
  description     = "rpc origins"
  enabled         = true
  minimum_origins = 1
  origin_steering {
    policy = "least_outstanding_requests"
  }

  notification_email = "alerts@subspace.network"
  check_regions      = ["WNAM", "ENAM", "WEU", "EEU", "SEAS", "NEAS"]
}

# create the pool of origins for domain evm nodes
resource "cloudflare_load_balancer_pool" "evm-nodes" {
  account_id = var.account_id
  name       = "evm-nodes"
  monitor    = cloudflare_load_balancer_monitor.check-evm-tcp.id
  origins {
    name    = "evm-0"
    address = "174.129.202.104"
  }
  origins {
    name    = "evm-1"
    address = "65.108.228.84"
  }
  description     = "domain evm origins"
  enabled         = true
  minimum_origins = 1
  origin_steering {
    policy = "least_outstanding_requests"
  }

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

# create the load balancer for domain evm nodes
resource "cloudflare_load_balancer" "evm-lb" {
  zone_id          = var.zone_id
  name             = "evm-lb"
  default_pool_ids = [cloudflare_load_balancer_pool.evm-nodes.id]
  fallback_pool_id = cloudflare_load_balancer_pool.evm-nodes.id
  description      = "EVM domain nodes load balancer"
  proxied          = true
}
