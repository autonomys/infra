output "ip_address_test_droplet" {
  value       = digitalocean_droplet.aries-test-a-nodes-farmer-relayer.ipv4_address
  description = "ip_address_test_droplet: "
}

output "ip_address_test_droplet_farmers" {
  value       = digitalocean_droplet.aries-farmers-network-a-nodes.ipv4_address
  description = "ip_address_test_droplet_farmers"
}
