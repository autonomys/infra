output "ip_address_droplet" {
  value       = digitalocean_droplet.telemetry-testing-subspace.ipv4_address
  description = "ip_address_droplet: "
}
