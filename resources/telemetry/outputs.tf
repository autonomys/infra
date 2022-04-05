output "ip_address_droplet" {
  value       = digitalocean_droplet.telemetry-subspace-frontend-backend.ipv4_address
  description = "ip_address_droplet: "
}

