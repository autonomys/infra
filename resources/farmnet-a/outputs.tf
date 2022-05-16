output "ip_address_aries-farmnet-a_droplet" {
  value       = digitalocean_droplet.aries-farmnet-a.ipv4_address
  description = "ip_address_droplet: "
}
