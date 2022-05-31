output "droplet-ipv4-address" {
  value       = digitalocean_droplet.gemini-1a[*].ipv4_address
  description = "Droplet IPV4 Address"
}

output "rpc_records" {
  value = cloudflare_record.rpc[*].hostname
}

output "bootstrap_records" {
  value = cloudflare_record.bootstrap[*].hostname
}
