data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "rpc" {
  count = length(var.droplet-regions)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "rpc-${count.index}-gemini-1"
  value   = digitalocean_droplet.gemini-1[count.index].ipv4_address
  type    = "A"
}

resource "cloudflare_record" "bootstrap" {
  count = length(var.droplet-regions)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}-gemini-1"
  value   = digitalocean_droplet.gemini-1[count.index].ipv4_address
  type    = "A"
}
