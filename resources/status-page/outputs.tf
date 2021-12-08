output "ip_address_dev_droplet" {
  value       = digitalocean_droplet.status-droplet.ipv4_address
  description = "ip_address_dev_droplet: "
}

