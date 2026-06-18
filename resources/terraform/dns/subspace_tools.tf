resource "cloudflare_dns_record" "subspace_tools_apex_1" {
  content  = "185.199.108.153"
  name     = "subspace.tools"
  proxied  = false
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_tools.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_tools_apex_2" {
  content  = "185.199.109.153"
  name     = "subspace.tools"
  proxied  = false
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_tools.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_tools_apex_3" {
  content  = "185.199.110.153"
  name     = "subspace.tools"
  proxied  = false
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_tools.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_tools_apex_4" {
  content  = "185.199.111.153"
  name     = "subspace.tools"
  proxied  = false
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_tools.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_tools_www" {
  content  = "autonomys-community.github.io"
  name     = "www.subspace.tools"
  proxied  = false
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.subspace_tools.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subspace_tools_github_pages_challenge" {
  content  = "7925f03f5b678341e6a6338360bc89"
  name     = "_github-pages-challenge-autonomys-community.subspace.tools"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_tools.zone_id
  settings = {}
}
