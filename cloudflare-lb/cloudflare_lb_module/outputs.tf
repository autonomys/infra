output "monitor_ids" {
  description = "The IDs of the created Cloudflare Load Balancer Monitors"
  value       = zipmap(keys(cloudflare_load_balancer_monitor.monitor), values(cloudflare_load_balancer_monitor.monitor)[*].id)
}

output "pool_ids" {
  description = "The IDs of the created Cloudflare Load Balancer Pools"
  value       = zipmap(keys(cloudflare_load_balancer_pool.pool), values(cloudflare_load_balancer_pool.pool)[*].id)
}

output "load_balancer_ids" {
  description = "The IDs of the created Cloudflare Load Balancers"
  value       = zipmap(keys(cloudflare_load_balancer.lb), values(cloudflare_load_balancer.lb)[*].id)
}

output "load_balancer_names" {
  description = "The names of the created Cloudflare Load Balancers"
  value       = zipmap(keys(cloudflare_load_balancer.lb), values(cloudflare_load_balancer.lb)[*].name)
}

output "dns_records" {
  description = "The details of the LB DNS Cloudflare Records"
  value = zipmap(
    keys(cloudflare_record.records),
    [for r in cloudflare_record.records : {
      id      = r.id,
      name    = r.name,
      type    = r.type,
      value   = r.value,
      proxied = r.proxied,
      tags    = r.tags
    }]
  )
}
