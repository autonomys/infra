# Outputs
output "cloudflare_lb_gemini" {
  description = "Cloudflare load balancer details"
  value       = module.cloudflare_lb_gemini.dns_records
}

output "cloudflare_monitor_ids" {
  description = "Cloudflare load balancer monitor IDs"
  value       = module.cloudflare_lb_gemini.monitor_ids
}

output "cloudflare_pool_ids" {
  description = "Cloudflare load balancer pool IDs"
  value       = module.cloudflare_lb_gemini.pool_ids
}

output "cloudflare_lb_ids" {
  description = "Cloudflare load balancer IDs"
  value       = module.cloudflare_lb_gemini.load_balancer_ids
}
