output "ip_address_dev_droplet" {
  value       = digitalocean_droplet.aries-dev-nodes-farmer-relayer.ipv4_address
  description = "ip_address_dev_droplet: "
}

output "ip_address_test_droplet" {
  value       = digitalocean_droplet.aries-test-nodes-farmer-relayer.ipv4_address
  description = "ip_address_test_droplet: "
}
