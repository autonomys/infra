resource "cloudflare_record" "continuum_co" {
  name    = "continuum.co"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "apex-loadbalancer.netlify.com"
  zone_id = data.cloudflare_zone.continuum_co.id
}

resource "cloudflare_record" "continuum_co_www" {
  name    = "www"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "continuum-collective.netlify.app"
  zone_id = data.cloudflare_zone.continuum_co.id
}
