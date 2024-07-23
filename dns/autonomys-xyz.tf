resource "cloudflare_record" "autonomys_xyz_1" {
  name    = "autonomys.xyz"
  proxied = false
  ttl     = 3600
  type    = "A"
  value   = "52.223.52.2"
  zone_id = data.cloudflare_zone.autonomys_xyz.id
}

resource "cloudflare_record" "autonomys_xyz_2" {
  name    = "autonomys.xyz"
  proxied = false
  ttl     = 3600
  type    = "A"
  value   = "35.71.142.77"
  zone_id = data.cloudflare_zone.autonomys_xyz.id
}

resource "cloudflare_record" "autonomys_xyz_www" {
  name    = "www"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "sites.framer.app"
  zone_id = data.cloudflare_zone.autonomys_xyz.id
}

resource "cloudflare_record" "autonomys_xyz_academy" {
  name    = "academy"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "a80ab473c4-hosting.gitbook.io"
  zone_id = data.cloudflare_zone.autonomys_xyz.id
}

// mailserver records for autonomys.xyz
resource "cloudflare_record" "mailserver_mx" {
  name     = "autonomys.xyz"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 1
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "smtp.google.com"
  zone_id  = data.cloudflare_zone.autonomys_xyz.id
}

resource "cloudflare_record" "dmarc" {
  zone_id = data.cloudflare_zone.autonomys_xyz.id
  name    = "_dmarc"
  type    = "TXT"
  value   = "v=DMARC1; p=quarantine; rua=mailto:dmarc@autonomys.xyz; ruf=mailto:dmarc@autonomys.xyz; aspf=r; adkim=r;"
  ttl     = 3600
}

resource "cloudflare_record" "spf" {
  zone_id = data.cloudflare_zone.autonomys_xyz.id
  name    = "@"
  type    = "TXT"
  value   = "v=spf1 a mx include:_spf.google.com include:subspace.network ~all"
  ttl     = 3600
}
