output "cloudflare-zone" {
  value       = data.cloudflare_zone.cloudflare_zone.id
  description = "Cloudflare's subspace.network Zone ID"
}

output "cloudflare-subspace-net-zone" {
  value       = data.cloudflare_zone.cloudflare_zone_subspace_net.id
  description = "Cloudflare's subspace.net Zone ID"
}
