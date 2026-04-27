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

resource "cloudflare_dns_record" "autonomys_org_apex" {
  content  = "192.0.2.1"
  name     = "autonomys.org"
  proxied  = true
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_org.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_org_www" {
  content  = "192.0.2.1"
  name     = "www.autonomys.org"
  proxied  = true
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_org.zone_id
  settings = {}
}

resource "cloudflare_ruleset" "autonomys_org_redirect_to_xyz" {
  zone_id     = data.cloudflare_zone.autonomys_org.zone_id
  name        = "Redirect autonomys.org to autonomys.xyz"
  description = "Redirect all autonomys.org and www.autonomys.org traffic to autonomys.xyz, preserving path and query string"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules = [
    {
      description = "Redirect autonomys.org and www.autonomys.org to autonomys.xyz"
      expression  = "(http.host eq \"autonomys.org\" or http.host eq \"www.autonomys.org\")"
      action      = "redirect"
      action_parameters = {
        from_value = {
          status_code           = 301
          preserve_query_string = true
          target_url = {
            expression = "concat(\"https://autonomys.xyz\", http.request.uri.path)"
          }
        }
      }
    }
  ]
}
