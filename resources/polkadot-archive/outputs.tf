output "ip_address_dev_droplet" {
  value       = digitalocean_droplet.polkadot-archive-droplet.ipv4_address
  description = "ip_address_dev_droplet: "
}

