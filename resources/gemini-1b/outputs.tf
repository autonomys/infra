output "droplet-ipv4-address" {
  value       = digitalocean_droplet.gemini-1b[*].ipv4_address
  description = "Droplet IPV4 Address"
}

output "rpc_records" {
  value = cloudflare_record.rpc[*].hostname
}

output "bootstrap_records" {
  value = cloudflare_record.bootstrap[*].hostname
}

#output "droplet-extra-ipv4-address" {
#  value       = digitalocean_droplet.gemini-1b-extra[*].ipv4_address
#  description = "Droplet IPV4 Address"
#}
#
#output "droplet-extra-us-ipv4-address" {
#  value       = digitalocean_droplet.gemini-1b-extra-US[*].ipv4_address
#  description = "Droplet IPV4 Address"
#}
