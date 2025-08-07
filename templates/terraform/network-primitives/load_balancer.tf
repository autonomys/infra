locals {
  consensus_load_balancer_count = var.consensus-rpc-node-config == null ? 0 : length(cloudflare_dns_record.consensus_rpc) < 1 ? 0 : var.consensus-rpc-node-config.enable-load-balancer ? 1 : 0
}

resource "cloudflare_load_balancer_monitor" "consensus_rpc_health_check" {
  depends_on  = [cloudflare_dns_record.consensus_rpc]
  count       = local.consensus_load_balancer_count
  account_id  = var.cloudflare_account_id
  type        = "tcp"
  port        = 30333
  interval    = 60
  retries     = 2
  timeout     = 5
  method      = "connection_established"
  description = "${title(var.network_name)} Consensus RPC Health Check"
  # this is not required for tcp connections
  # but cloudflare seems to set default and it causes the tfstate to mismatch
  path = "/"
  # we want all the rpcs to be up atleast 2 health checks before we mark them healthy
  consecutive_up = 2
  # if monitored origin fails even once, mark it as unhealthy
  consecutive_down = 1
}

resource "cloudflare_load_balancer_pool" "consensus_rpc_lb_pool" {
  depends_on      = [cloudflare_load_balancer_monitor.consensus_rpc_health_check]
  count           = local.consensus_load_balancer_count
  account_id      = var.cloudflare_account_id
  name            = "${var.network_name}-consensus-rpc-lb-pool"
  description     = "${title(var.network_name)} Consensus RPC Load balancer Pool"
  enabled         = true
  minimum_origins = length(cloudflare_dns_record.consensus_rpc)
  monitor         = cloudflare_load_balancer_monitor.consensus_rpc_health_check[0].id

  origin_steering = {
    policy = "least_connections"
  }

  origins = [
    for dns_record in cloudflare_dns_record.consensus_rpc : {
      name    = trimsuffix(dns_record.name, ".${data.cloudflare_zone.cloudflare_zone.name}")
      address = dns_record.content
      enabled = true
    }
  ]
}

resource "cloudflare_load_balancer" "consensus_rpc_lb" {
  depends_on       = [cloudflare_load_balancer_pool.consensus_rpc_lb_pool]
  count            = local.consensus_load_balancer_count
  zone_id          = data.cloudflare_zone.cloudflare_zone.zone_id
  name             = "${var.consensus-rpc-node-config.dns-prefix}.${var.network_name}.${data.cloudflare_zone.cloudflare_zone.name}"
  description      = "${title(var.network_name)} Consensus RPC load balancer"
  proxied          = true
  enabled          = true
  default_pools    = [cloudflare_load_balancer_pool.consensus_rpc_lb_pool[0].id]
  fallback_pool    = cloudflare_load_balancer_pool.consensus_rpc_lb_pool[0].id
  session_affinity = "ip_cookie"
  # set it to 3 days
  session_affinity_ttl = 259200
  steering_policy      = "least_connections"
}

locals {
  domain_load_balancer_enabled = var.domain-rpc-node-config == null ? false : length(cloudflare_dns_record.domain_rpc) < 1 ? false : var.domain-rpc-node-config.enable-load-balancer

  domain_name_map_grouped = local.domain_load_balancer_enabled ? {
    for rpc_node in var.domain-rpc-node-config.rpc-nodes :
    rpc_node.domain-id => rpc_node.domain-name...
  } : {}

  domain_name_map = {
    for domain-id, domain-name in local.domain_name_map_grouped :
    domain-id => domain-name[0]
  }

  # seems like using domain_name_map here does not work for some reason
  # maybe due to locals cannot rely on another? Will need to investigate
  # until them we just do a inner loop but ideal but that seems to work
  domain_ipv4_map_grouped = local.domain_load_balancer_enabled ? {
    for index, rpc_node in var.domain-rpc-node-config.rpc-nodes :
    rpc_node.domain-id => [
      for index_inner, rpc_node_inner in var.domain-rpc-node-config.rpc-nodes :
      aws_instance.domain_rpc_nodes[index_inner].public_ip if rpc_node_inner.domain-id == rpc_node.domain-id
    ]...
  } : {}

  domain_ipv4_map = {
    for domain-id, ipv4 in local.domain_ipv4_map_grouped :
    domain-id => ipv4[0]
  }


  domain_index_map_grouped = local.domain_load_balancer_enabled ? {
    for index, rpc_node in var.domain-rpc-node-config.rpc-nodes :
    rpc_node.domain-id => [
      for index_inner, rpc_node_inner in var.domain-rpc-node-config.rpc-nodes :
      rpc_node_inner.index if rpc_node_inner.domain-id == rpc_node.domain-id
    ]...
  } : {}

  domain_index_map = {
    for domain-id, indexes in local.domain_index_map_grouped :
    domain-id => indexes[0]
  }
}

resource "cloudflare_load_balancer_monitor" "domain_rpc_health_check" {
  for_each    = local.domain_name_map
  depends_on  = [cloudflare_dns_record.domain_rpc]
  account_id  = var.cloudflare_account_id
  type        = "tcp"
  port        = 30334
  interval    = 60
  retries     = 2
  timeout     = 5
  method      = "connection_established"
  description = "${title(var.network_name)} Domain ${each.key} RPC Health Check"
  # this is not required for tcp connections
  # but cloudflare seems to set default and it causes the tfstate to mismatch
  path = "/"
  # we want all the rpcs to be up atleast 2 health checks before we mark them healthy
  consecutive_up = 2
  # if monitored origin fails even once, mark it as unhealthy
  consecutive_down = 1
}

resource "cloudflare_load_balancer_pool" "domain_rpc_lb_pool" {
  for_each        = local.domain_name_map
  depends_on      = [cloudflare_load_balancer_monitor.domain_rpc_health_check]
  account_id      = var.cloudflare_account_id
  name            = "${var.network_name}-domain-${each.key}-rpc-lb-pool"
  description     = "${title(var.network_name)} Domain ${each.key} RPC Load balancer Pool"
  enabled         = true
  minimum_origins = length(local.domain_ipv4_map[each.key])
  monitor         = cloudflare_load_balancer_monitor.domain_rpc_health_check[each.key].id

  origin_steering = {
    policy = "least_connections"
  }

  origins = [
    for index, ipv4 in local.domain_ipv4_map[each.key] : {
      name    = "${local.domain_name_map[each.key]}-${local.domain_index_map[each.key][index]}.${var.network_name}"
      address = ipv4
      enabled = true
    }
  ]
}

resource "cloudflare_load_balancer" "domain_rpc_lb" {
  depends_on       = [cloudflare_load_balancer_pool.domain_rpc_lb_pool]
  for_each         = local.domain_name_map
  zone_id          = data.cloudflare_zone.cloudflare_zone.zone_id
  name             = "${each.value}.${var.network_name}.${data.cloudflare_zone.cloudflare_zone.name}"
  description      = "${title(var.network_name)} Domain ${each.value} RPC load balancer"
  proxied          = true
  enabled          = true
  default_pools    = [cloudflare_load_balancer_pool.domain_rpc_lb_pool[each.key].id]
  fallback_pool    = cloudflare_load_balancer_pool.domain_rpc_lb_pool[each.key].id
  session_affinity = "ip_cookie"
  # set it to 3 days
  session_affinity_ttl = 259200
  steering_policy      = "least_connections"
}
