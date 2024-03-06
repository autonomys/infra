output "cloudflare_dns_record_details" {
    value = { for k, record in cloudflare_record.main : record.name => {
        id      = record.id
        zone_id = record.zone_id
        type    = record.type
        ttl     = record.ttl
        name    = record.name
        proxied = record.proxied
        value   = record.value
        tags    = record.tags
        comment = record.comment
      }
    }
  }
