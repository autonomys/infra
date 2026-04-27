resource "cloudflare_dns_record" "autonomys_org_mx" {
  content  = "smtp.google.com"
  name     = "autonomys.org"
  priority = 1
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.autonomys_org.zone_id
  settings = {}
}
