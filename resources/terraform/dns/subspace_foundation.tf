resource "cloudflare_dns_record" "subspace_foundation" {
  content  = "198.202.211.1"
  name     = "subspace.foundation"
  proxied  = false
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_substation" {
  content  = local.proxied_data.subspace_foundation.substation
  name     = "substation.subspace.foundation"
  proxied  = true
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_telemetry_ops" {
  content  = "65.108.232.53"
  name     = "telemetry-ops.subspace.foundation"
  proxied  = false
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_telemetry" {
  content  = "44.244.168.0"
  name     = "telemetry.subspace.foundation"
  proxied  = false
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_ambassador" {
  content  = "external.notion.site"
  name     = "ambassador.subspace.foundation"
  proxied  = false
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_www" {
  content  = "cdn.webflow.com"
  name     = "www.subspace.foundation"
  proxied  = false
  ttl      = 3600
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_mx" {
  content  = "smtp.google.com"
  name     = "subspace.foundation"
  priority = 1
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_gh" {
  content  = "\"3ac34856fd\""
  name     = "_gh-subspace-o.subspace.foundation"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_notion_ambassador" {
  content  = "\"13189b83-0b39-8161-a840-00701292a577\""
  name     = "_notion-dcv.ambassador.subspace.foundation"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_notion_www" {
  content  = "\"111b66ba-c532-81eb-abf2-0070cacddff4\""
  name     = "_notion-dcv.www.subspace.foundation"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_google_site_verification" {
  content  = "\"GOOGLE-SITE-VERIFICATION=NZ1J8C6RWMBSXL4AHE6NJHTHJH7AEGUMXI25GDDYPYA\""
  name     = "subspace.foundation"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_spf" {
  content  = "\"v=spf1 a mx include:_spf.google.com include:subspace.network ~all\""
  name     = "subspace.foundation"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_webflow_verification" {
  content  = "\"one-time-verification=932af4b2-9cc7-48d6-8619-63e9392377fd\""
  name     = "_webflow.www.subspace.foundation"
  proxied  = false
  ttl      = 3600
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_foundation_github_pages_beneficiary" {
  content  = "\"329f7b11df0e7f710435e3838ecaf7\""
  name     = "_github-pages-challenge-subspace.beneficiary.subspace.foundation"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_foundation.zone_id
  settings = {}
}
