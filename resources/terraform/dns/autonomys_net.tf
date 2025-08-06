resource "cloudflare_dns_record" "autonomys_net_academy" {
  content  = local.proxied_data.autonomys_net.academy
  name     = "academy.autonomys.net"
  proxied  = true
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net" {
  content  = local.proxied_data.autonomys_net.root
  name     = "autonomys.net"
  proxied  = true
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_www" {
  content  = local.proxied_data.autonomys_net.www
  name     = "www.autonomys.net"
  proxied  = true
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_pm_bounces" {
  content  = "pm.mtasv.net"
  name     = "pm-bounces.autonomys.net"
  proxied  = false
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_mx_1" {
  content  = "alt4.aspmx.l.google.com"
  name     = "autonomys.net"
  priority = 10
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_mx_2" {
  content  = "alt3.aspmx.l.google.com"
  name     = "autonomys.net"
  priority = 10
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_mx_3" {
  content  = "alt2.aspmx.l.google.com"
  name     = "autonomys.net"
  priority = 5
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_mx_4" {
  content  = "alt1.aspmx.l.google.com"
  name     = "autonomys.net"
  priority = 5
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_mx_5" {
  content  = "aspmx.l.google.com"
  name     = "autonomys.net"
  priority = 1
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_pm_dkim" {
  content  = "k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDBQprLmt9d8rju4lsi/Pc0YHf98rH4uRVYV9xkmkQG6V+G15tqxtsdacY1/Cw3F+Cgu8rgcb5f8DfxBqZnhG5mhuBcM1/ItpvJgkEATuF7abJdalNnjsrfGiwNA0WK1OiyCh4nEsgd+RQz9vw47Q6JvpPAOcsytvaqeRq+q8cgWQIDAQAB"
  name     = "20240702142005pm._domainkey.autonomys.net"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_spf" {
  content  = "v=spf1 a mx include:spf.mtasv.net include:_spf.google.com include:subspace.network ~all"
  name     = "autonomys.net"
  proxied  = false
  ttl      = 60
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_google_site_verification_1" {
  content  = "google-site-verification=B02lIX1RIldgU03z5fVmmmijoCGh3tep5nKrIODLSrw"
  name     = "autonomys.net"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_google_site_verification_2" {
  content  = "google-site-verification=pShEYAbVkgD-1mqI_CQYeNm55ASPEbaS0_keedYGKL4"
  name     = "autonomys.net"
  proxied  = false
  ttl      = 60
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_google_site_verification_3" {
  content  = "google-site-verification=DOZLQDO-Bv6HOoRxIEnsowoQ_oQbpETB6t63jn41sfU"
  name     = "autonomys.net"
  proxied  = false
  ttl      = 60
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_dmarc" {
  content  = "v=DMARC1; p=quarantine; rua=mailto:dmarc@autonomys.net; ruf=mailto:dmarc@autonomys.net; aspf=r; adkim=r;"
  name     = "_dmarc.autonomys.net"
  proxied  = false
  ttl      = 60
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_net_google_dkim" {
  content  = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCgon8mFK0WK9I7pA2L8S221PHwT1bk39XRDzd1yufKS5wYlJhyBCo+OSxHrI2HB6Fy+BQ+X4L+6yWGTAi+6YLXMsdLvMGjuYHWzypNlUuoh77ygHoNy8XTLRlG0FXxQ32NOme68+7poNByX+sbz9NXDnv/eJFjNBkG/efOp+amiQIDAQAB"
  name     = "google._domainkey.autonomys.net"
  proxied  = false
  ttl      = 60
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_net.zone_id
  settings = {}
}

