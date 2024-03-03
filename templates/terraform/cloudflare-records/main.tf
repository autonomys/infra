resource "cloudflare_record" "main" {
  for_each = { for cf in var.cloudflare_records : cf.name => cf }
  zone_id  = each.value.zone_id
  type     = each.value.type
  ttl      = each.value.ttl
  name     = each.value.name
  proxied  = each.value.proxied
  value    = each.value.value
  tags     = each.value.tags
}
