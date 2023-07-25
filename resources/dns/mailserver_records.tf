// mailserver records for subspace.network
resource "cloudflare_record" "mailserver_mx_1" {
  name     = "subspace.network"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 1
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "mailserver_mx_2" {
  name     = "subspace.network"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 5
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt1.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "mailserver_mx_3" {
  name     = "subspace.network"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 5
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt2.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "mailserver_mx_4" {
  name     = "subspace.network"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 10
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt4.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "mailserver_mx_5" {
  name     = "subspace.network"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 10
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt3.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "mailserver_dkim_default" {
  name    = "default._domainkey"
  comment = "Default DKIM"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7zwrsOLB+eJ9SG1t7+OwOT2BuacTImFHozl8I/ mypg7rhtp4i1NpkSnjjDC3FdXXiUhsHTvAUvg5nMtGp3nCwwQYna0C8Jo7dbt3+NUVLj9KCBBBegxPS/WoJghPSbiKq4T/SBdM0K ShrVn7C/1blWA+N4XxOwmVtELV8POMwRYCzlrxCi3kdjbRY+4gXYKmcc7MSRi5ubyR7P/+K1/CkLbJa1SbxdS6/zMRIzPH/6vOR6 be1Qkw5PFsYu0gYbz3QDqYxaUTS3euWSPE3uLnPQEgAryX3SlKQB8uyjNbxF86ukslwwe9Q5cCZ1UPsl/89qcBRirnJbfoGlwb5j rX3QIDAQAB"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "mailserver_dmarc" {
  name    = "_dmarc"
  comment = "DMARC for communications"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=DMARC1; p=reject; pct=100; rua=mailto:g5oqy2di@ag.dmarcian.com, mailto:admin@subspace.network; ruf=mailto:admin@subspace.network"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "mailserver_dkim" {
  name    = "_domainkey"
  comment = "DKIM for mail"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=DKIM1; o=~"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "mailserver_dkim_google" {
  name    = "google._domainkey"
  comment = "DKIM for mail specific to Gmail"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyqbz3f5O6pOl9LK3zOmKkczcK9aCdB34tSzDkA ZRD0g+OtBhlyWyzNeQGsrVianIfM9xyfZ7MVJK7sB/VGKIFIe5glb/Lh9tf/kLCRbkOnaafiXP5tOk4DC+mBpHOjyT0GgX5x4hxg oLmeJOrRLSu1niPQY/VqMtNsYa9+gAIo0YZnZeNi2w3FjWaslm5F7uI6mISdH3HZchqhzx2E6Ct+VJhLM0Ir+6v3qV5ylArtJzc+ PoTGdk65n5oq+Ioj9oTK4VmJunZ6jaU2Vimo+2TTAhBtRWQCa8Xy15/3kVZXiKJ4ddtPDnzSEval4er4SksIhtVYaxkeanU7pGbK w1SQIDAQAB"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "mailserver_spf" {
  name    = "subspace.network"
  comment = "SPF record"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=spf1 +a +a:ns1.us145.siteground.us include:_spf.google.com +mx ~all"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "mail" {
  name    = "mail"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "subspace.network"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}


// ## mailserver records for subspace.net ## 
resource "cloudflare_record" "mailserver_mx_net_1" {
  name     = "subspace.net"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 1
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone_subspace_net.id
}

resource "cloudflare_record" "mailserver_mx_net_2" {
  name     = "subspace.net"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 5
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt1.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone_subspace_net.id
}

resource "cloudflare_record" "mailserver_mx_net_3" {
  name     = "subspace.net"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 5
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt2.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone_subspace_net.id
}

resource "cloudflare_record" "mailserver_mx_net_4" {
  name     = "subspace.net"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 10
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt3.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone_subspace_net.id
}

resource "cloudflare_record" "mailserver_mx__net_5" {
  name     = "subspace.net"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 10
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt4.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone_subspace_net.id
}

resource "cloudflare_record" "mailserver_net_dmarc" {
  name    = "_dmarc"
  comment = "DMARC for communications"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=DMARC1; p=reject; adkim=s"
  zone_id = data.cloudflare_zone.cloudflare_zone_subspace_net.id
}

resource "cloudflare_record" "mailserver_dkim_net_google" {
  name    = "google._domainkey"
  comment = "DKIM for mail specific to Gmail"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhV/Ry2nJ1On1URw7A8YICoGP1TVl/PntwJnVobB+51axauDpHd4bGf7BxgA2JeUVHgB4YnUeecwkLxkB/gvRnCdLKUCAIF4cUsDV/e2McgqX2zo63iehtnu99d7hVUDpGql/7icPjh2XQYpCqBlUOPtXMArRtqjN7LgwjmYKXYJJ/9y4jAgKluGirvaIuCoQDxHhXKvElaxhfwDv4Wj27Vu/BXWq/4vDKxIcByxtNr9GVMDnH0XGzhYVxJ3vfz22BqN1E52IRXkb0A0RdJVfwm5+yNM5xuucyXJqax44bNbpXnX0RLodpffco78dAWbXDpaabcYSmJbhHLd/pfCePQIDAQAB"
  zone_id = data.cloudflare_zone.cloudflare_zone_subspace_net.id
}

resource "cloudflare_record" "mailserver_net_spf" {
  name    = "subspace.net"
  comment = "SPF record"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=spf1 include:_spf.google.com -all"
  zone_id = data.cloudflare_zone.cloudflare_zone_subspace_net.id
}

resource "cloudflare_record" "mail_net" {
  name    = "mail"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "subspace.net"
  zone_id = data.cloudflare_zone.cloudflare_zone_subspace_net.id
}
