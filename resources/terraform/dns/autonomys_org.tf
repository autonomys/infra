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

resource "cloudflare_dns_record" "autonomys_org_google_dkim" {
  content  = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAk21qDpKceJPhmfMG9q2kbMnObBlPacoMQD7dM7eWLCMmL9HAWKLleUT3Cy8ORraz11yn3bxACTh48baVsYTVIBbAJBzHhgCjOsgd/EyJ3U2NXc3BXiYdpbNFWSIc5/GQnTVu9+ao1/hZC+0JCv/KaRlIFyUP7O7K+7c9naosWoTj/SvctzWpcUGdGXeRSYzJNaQpJQld5ZwR3yeCaEA4jV6M+M30nnv7zm4Sjqeo6pAvU5OlEsdWdp1ZGt17yNijdpEJiljqrru52DdnrxjqglY12dK+5c3XIXQptMWs4jOTbJCfdpMh8NDE2IPS9PH3W10vQ95K0PeH8Bm8bmrcIwIDAQAB"
  name     = "google-org._domainkey.autonomys.org"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_org.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_org_spf" {
  content  = "v=spf1 include:_spf.google.com include:subspace.network include:49004947.spf07.hubspotemail.net -all"
  name     = "autonomys.org"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_org.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "autonomys_org_dmarc" {
  content  = "v=DMARC1; p=reject; pct=50; rua=mailto:admin@autonomys.org; ruf=mailto:admin@autonomys.org; aspf=r; adkim=r;"
  name     = "_dmarc.autonomys.org"
  proxied  = false
  ttl      = 1
  type     = "TXT"
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
