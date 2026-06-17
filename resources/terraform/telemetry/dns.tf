data "cloudflare_zone" "subspace_network" {
  filter = {
    name = "subspace.network"
  }
}

data "cloudflare_zone" "subspace_foundation" {
  filter = {
    name = "subspace.foundation"
  }
}

resource "cloudflare_dns_record" "telemetry_subspace_network" {
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  name    = "telemetry.subspace.network"
  content = aws_instance.telemetry.public_ip
  type    = "A"
  ttl     = 1
  proxied = false
}

resource "cloudflare_dns_record" "telemetry_subspace_foundation" {
  zone_id = data.cloudflare_zone.subspace_foundation.zone_id
  name    = "telemetry.subspace.foundation"
  content = aws_instance.telemetry.public_ip
  type    = "A"
  ttl     = 1
  proxied = false
}
