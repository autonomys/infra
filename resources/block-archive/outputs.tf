output "ip_address_dev_droplet" {
  value       = digitalocean_droplet.subspace-nodes-relayer-backend-2021.ipv4_address
  description = "ip_address_dev_droplet: "
}

