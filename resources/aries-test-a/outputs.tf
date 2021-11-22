output "ip_address_test_droplet" {
  value       = digitalocean_droplet.aries-test-a-nodes-farmer-relayer.ipv4_address
  description = "ip_address_test_droplet: "
}
