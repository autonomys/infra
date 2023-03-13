output "cloudflare-zone" {
  value       = data.cloudflare_zone.cloudflare_zone.id
  description = "Cloudflare's subspace.network Zone ID"
}
