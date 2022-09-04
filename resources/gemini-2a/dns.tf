data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

#resource "cloudflare_record" "rpc" {
#  count = length(digitalocean_droplet.gemini-2a-rpc-nodes)
#  zone_id = data.cloudflare_zone.cloudflare_zone.id
#  name    = "rpc-${count.index}.gemini-2a"
#  value   = digitalocean_droplet.gemini-2a-rpc-nodes[count.index].ipv4_address
#  type    = "A"
#}
