resource "cloudflare_dns_record" "subspace_net_mx_1" {
  content  = "alt2.aspmx.l.google.com"
  name     = "subspace.net"
  priority = 5
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_net_mx_2" {
  content  = "alt1.aspmx.l.google.com"
  name     = "subspace.net"
  priority = 5
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_net_mx_3" {
  content  = "alt4.aspmx.l.google.com"
  name     = "subspace.net"
  priority = 10
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_net_mx_4" {
  content  = "alt3.aspmx.l.google.com"
  name     = "subspace.net"
  priority = 10
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_net_mx_5" {
  content  = "aspmx.l.google.com"
  name     = "subspace.net"
  priority = 1
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_net_dmarc" {
  content  = "v=DMARC1; p=reject; adkim=s"
  name     = "_dmarc.subspace.net"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_net_dkim" {
  content  = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhV/Ry2nJ1On1URw7A8YICoGP1TVl/PntwJnVobB+51axauDpHd4bGf7BxgA2JeUVHgB4YnUeecwkLxkB/gvRnCdLKUCAIF4cUsDV/e2McgqX2zo63iehtnu99d7hVUDpGql/7icPjh2XQYpCqBlUOPtXMArRtqjN7LgwjmYKXYJJ/9y4jAgKluGirvaIuCoQDxHhXKvElaxhfwDv4Wj27Vu/BXWq/4vDKxIcByxtNr9GVMDnH0XGzhYVxJ3vfz22BqN1E52IRXkb0A0RdJVfwm5+yNM5xuucyXJqax44bNbpXnX0RLodpffco78dAWbXDpaabcYSmJbhHLd/pfCePQIDAQAB"
  name     = "google._domainkey.subspace.net"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_net.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_net_spf" {
  content  = "v=spf1 include:_spf.google.com -all"
  name     = "subspace.net"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_net.zone_id
  settings = {}
}

