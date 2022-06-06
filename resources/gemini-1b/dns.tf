data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "rpc" {
  count = length(digitalocean_droplet.gemini-1b)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "rpc-${count.index}.gemini-1b"
  value   = digitalocean_droplet.gemini-1b[count.index].ipv4_address
  type    = "A"
}

resource "cloudflare_record" "bootstrap" {
  count = length(digitalocean_droplet.gemini-1b)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}.gemini-1b"
  value   = digitalocean_droplet.gemini-1b[count.index].ipv4_address
  type    = "A"
}
