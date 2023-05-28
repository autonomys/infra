output "dns-records" {
  value = [
    cloudflare_record.squid[*].hostname,
    cloudflare_record.archive[*].hostname,
  ]
}

output "do-squid-node-ipv4-addresses" {
  value       = digitalocean_droplet.squid-nodes[*].ipv4_address
  description = "DO full node IPv4 Addresses"
}

output "do-archive-node-ipv4-addresses" {
  value       = digitalocean_droplet.archive-nodes[*].ipv4_address
  description = "DO Farmer node IPv4 Addresses"
}
