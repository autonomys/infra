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

resource "cloudflare_record" "bootstrap" {
  count = length(local.bootstrap_nodes_ip_v4)
  zone_id = data.cloudflare_zone.cloudflare_zone.id
  name    = "bootstrap-${count.index}.gemini-2a"
  value   = local.bootstrap_nodes_ip_v4[count.index]
  type    = "A"
}
