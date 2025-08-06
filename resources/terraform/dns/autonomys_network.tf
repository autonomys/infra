resource "cloudflare_dns_record" "autonomys_netwotk_to_net" {
  content  = "autonomys.net"
  name     = "autonomys.network"
  proxied  = true
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.autonomys_network.zone_id
  settings = {}
}

