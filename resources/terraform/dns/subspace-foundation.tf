resource "cloudflare_record" "subspace_foundation_1" {
  name    = "subspace.foundation"
  proxied = false
  ttl     = 3600
  type    = "A"
  value   = "192.64.119.47"
  zone_id = data.cloudflare_zone.subspace_foundation.id
}

resource "cloudflare_record" "subspace_foundation_www" {
  name    = "www"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "external.notion.site"
  zone_id = data.cloudflare_zone.subspace_foundation.id
}

// mailserver records for subspace.foundation
resource "cloudflare_record" "mailserver_mx" {
  name     = "subspace.foundation"
  comment  = "MX record pointing to our preferred mailserver"
  priority = 1
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "smtp.google.com"
  zone_id  = data.cloudflare_zone.subspace_foundation.id
}

resource "cloudflare_record" "subspace_foundation_notion_txt" {
  zone_id = data.cloudflare_zone.subspace_foundation.id
  name    = "_notion-dcv.www."
  type    = "TXT"
  value   = "111b66ba-c532-81eb-abf2-0070cacddff4"
  ttl     = 3600
}

// subspace telemetry
resource "cloudflare_record" "telemetry" {
  comment = "Subspace Telemetry"
  name    = "telemetry"
  proxied = true
  ttl     = 1
  type    = "A"
  value   = "35.89.37.220"
  zone_id = data.cloudflare_zone.subspace_foundation.id
}

// subspace telemetry (substation)
resource "cloudflare_record" "substation" {
  comment = "Subspace Telemetry (Substation)"
  name    = "substation"
  proxied = true
  ttl     = 1
  type    = "A"
  value   = "35.89.37.220"
  zone_id = data.cloudflare_zone.subspace_foundation.id
}

resource "cloudflare_record" "ambassador" {
  name    = "ambassador"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "external.notion.site"
  zone_id = data.cloudflare_zone.subspace_foundation.id
}

// DNS record for _notion-dcv.ambassador
resource "cloudflare_record" "ambassador_notion_txt" {
  zone_id = data.cloudflare_zone.subspace_foundation.id
  name    = "_notion-dcv.ambassador"
  type    = "TXT"
  value   = "13189b83-0b39-8161-a840-00701292a577"
  ttl     = 3600
}

resource "cloudflare_record" "bootstrap_0_devnet" {
  zone_id = data.cloudflare_zone.subspace_foundation.id
  name    = "bootstrap-0.devnet"
  type    = "A"
  value   = "173.208.0.26"
  ttl     = 1 # Auto
  proxied = false
}

resource "cloudflare_record" "bootstrap_0_mainnet" {
  zone_id = data.cloudflare_zone.subspace_foundation.id
  name    = "bootstrap-0.mainnet"
  type    = "A"
  value   = "173.208.0.26"
  ttl     = 1 # Auto
  proxied = false
}

resource "cloudflare_record" "rpc_devnet" {
  zone_id = data.cloudflare_zone.subspace_foundation.id
  name    = "rpc.devnet"
  type    = "A"
  value   = "173.208.0.25"
  ttl     = 1 # Auto
  proxied = false
}

resource "cloudflare_record" "rpc_mainnet" {
  zone_id = data.cloudflare_zone.subspace_foundation.id
  name    = "rpc.mainnet"
  type    = "A"
  value   = "173.208.0.25"
  ttl     = 1 # Auto
  proxied = false
}

resource "cloudflare_record" "rpc_taurus" {
  zone_id = data.cloudflare_zone.subspace_foundation.id
  name    = "rpc.taurus"
  type    = "A"
  value   = "65.108.225.226"
  ttl     = 1
  proxied = false
}
