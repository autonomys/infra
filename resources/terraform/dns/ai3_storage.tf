resource "cloudflare_dns_record" "ai3_storage_apex_loadbalancer" {
  content  = "apex-loadbalancer.netlify.com"
  name     = "ai3.storage"
  proxied  = false
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.ai3_storage.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "ai3_storage_auto_drive_demo" {
  content  = "auto-drive-demo.netlify.app"
  name     = "www.ai3.storage"
  proxied  = false
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.ai3_storage.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "ai3_storage_auto_drive_explorer" {
  content  = "auto-drive-storage.netlify.app"
  name     = "explorer.ai3.storage"
  proxied  = false
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.ai3_storage.zone_id
  settings = {}
}

