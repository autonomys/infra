resource "cloudflare_record" "continuim_cc" {
  name    = "continuim.cc"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "proxy-ssl.webflow.com"
  zone_id = data.cloudflare_zone.continuim_cc.id
}

resource "cloudflare_record" "continuim_cc_www" {
  name    = "www"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "proxy-ssl.webflow.com"
  zone_id = data.cloudflare_zone.continuim_cc.id
}
