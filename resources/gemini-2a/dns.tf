data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "rpc" {
  count = length(var.hetzner_rpc_node_ips)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "eu-${count.index}.gemini-2a"
  value   = var.hetzner_rpc_node_ips[count.index]
  type    = "A"
}
