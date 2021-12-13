output "ip_address_test_droplet" {
  value       = digitalocean_droplet.aries-farmers-network-nodes.ipv4_address
  description = "ip_address_test_droplet: "
}
