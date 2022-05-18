output "droplet-ipv4-address" {
  value       = digitalocean_droplet.gemini-1[*].ipv4_address
  description = "Droplet IPV4 Address"
}
