data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "rpc" {
  count = length(var.droplet-regions)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "rpc-${count.index}.gemini-1"
  value   = digitalocean_droplet.gemini-1[count.index].ipv4_address
  type    = "A"
}

resource "cloudflare_record" "bootstrap" {
  count = length(var.droplet-regions)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}.gemini-1"
  value   = digitalocean_droplet.gemini-1[count.index].ipv4_address
  type    = "A"
}

resource "cloudflare_load_balancer_pool" "gemini-1" {
  name = "Gemini 1 Origin pool"

  dynamic "origins" {
    for_each = cloudflare_record.rpc
    content {
      name = origins.value["name"]
      address = "${origins.value["name"]}.${data.cloudflare_zone.cloudflare_zone.name}"
    }
  }
}

resource "cloudflare_load_balancer" "gemini-1" {
  default_pool_ids = [cloudflare_load_balancer_pool.gemini-1.id]
  fallback_pool_id = cloudflare_load_balancer_pool.gemini-1.id
  name             = "Gemini 1 Load balancer"
  zone_id          = data.cloudflare_zone.cloudflare_zone.id
}
