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

// mailserver records for continuum.co
resource "cloudflare_record" "mailserver_mx_1" {
  name     = "continuum.co"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 1
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.continuum_co.id
}

resource "cloudflare_record" "mailserver_mx_2" {
  name     = "continuum.co"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 5
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt1.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.continuum_co.id
}

resource "cloudflare_record" "mailserver_mx_3" {
  name     = "continuum.co"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 5
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt2.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.continuum_co.id
}

resource "cloudflare_record" "mailserver_mx_4" {
  name     = "continuum.co"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 10
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt3.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.continuum_co.id
}

resource "cloudflare_record" "mailserver_mx_5" {
  name     = "continuum.co"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 10
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt4.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.continuum_co.id
}
