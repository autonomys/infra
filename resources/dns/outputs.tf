output "cloudflare-zone" {
  value       = data.cloudflare_zone.subspace_network.id
  description = "Cloudflare's subspace.network Zone ID"
}

output "cloudflare-subspace-net-zone" {
  value       = data.cloudflare_zone.subspace_net.id
  description = "Cloudflare's subspace.net Zone ID"
}

output "cloudflare-continuim-cc-zone" {
  value       = data.cloudflare_zone.continuim_cc.id
  description = "Cloudflare's continuim.cc Zone ID"
}
