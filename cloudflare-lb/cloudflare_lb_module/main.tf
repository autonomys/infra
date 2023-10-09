data "cloudflare_zones" "subspace" {
  filter {
    name   = var.domain
    status = "active"
  }
}

locals {
  existing_records_set = try({ for cf in var.records : cf.name => cf }, {})
}

data "cloudflare_record" "existing_records" {
  for_each = local.existing_records_set

  zone_id  = var.zone_id
  hostname = each.value.hostname
  type     = each.value.type
}

resource "cloudflare_record" "records" {
  for_each = { for cf in var.records : cf.name => cf if !contains(keys(data.cloudflare_record.existing_records), cf.name) }

  zone_id = var.zone_id
  name    = each.value.hostname
  value   = each.value.value
  type    = each.value.type
  proxied = true
  tags    = each.value.tags
}

resource "cloudflare_load_balancer_monitor" "monitor" {
  for_each = { for monitor in var.monitors : monitor.name => monitor }

  account_id     = var.account_id
  type           = "tcp"
  expected_codes = each.value.expected_codes
  timeout        = each.value.timeout
  interval       = each.value.interval
  retries        = each.value.retries
  port           = each.value.port
  description    = each.value.description
}

resource "cloudflare_load_balancer_pool" "pool" {
  for_each = { for pool in var.monitors : pool.name => pool }

  account_id = var.account_id
  name       = each.key
  monitor    = cloudflare_load_balancer_monitor.monitor[each.key].id

  dynamic "origins" {
    for_each = var.records
    content {
      name    = origins.value.name
      address = origins.value.value
    }
  }

  description     = "pool for ${each.key}"
  enabled         = true
  minimum_origins = 1
  origin_steering {
    policy = "least_outstanding_requests"
  }

  notification_email = "alerts@subspace.network"
  check_regions      = ["WNAM", "ENAM", "WEU", "EEU", "SEAS", "NEAS"]
}

resource "cloudflare_load_balancer" "lb" {
  for_each = { for lb in var.load_balancers : lb.name => lb }

  zone_id          = var.zone_id
  name             = each.key
  default_pool_ids = [cloudflare_load_balancer_pool.pool[each.key].id]
  fallback_pool_id = cloudflare_load_balancer_pool.pool[each.key].id
  description      = each.value.description
  proxied          = true
}
