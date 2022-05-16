output "ip_address_aries-test-b-nodes-farmer-relayer_droplet" {
  value       = digitalocean_droplet.aries-test-b-nodes-farmer-relayer.ipv4_address
  description = "ip_address_test_droplet: "
}

output "ip_address_aries-relaynet-a_droplet" {
  value       = digitalocean_droplet.aries-relaynet-a.ipv4_address
  description = "ip_address_test_droplet_2: "
}

output "ip_address_aries-farmers-network-b-nodes_droplet" {
  value       = digitalocean_droplet.aries-farmers-network-b-nodes.ipv4_address
  description = "ip_address_test_droplet_farmers"
}
