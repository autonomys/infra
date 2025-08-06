resource "cloudflare_dns_record" "continuum_co_to_xyz" {
  content  = "autonomys.xyz"
  name     = "continuum.co"
  proxied  = true
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_www_to_xyz" {
  content  = "autonomys.xyz"
  name     = "www.continuum.co"
  proxied  = true
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_mx_1" {
  content  = "alt1.aspmx.l.google.com"
  name     = "continuum.co"
  priority = 5
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_mx_2" {
  content  = "alt4.aspmx.l.google.com"
  name     = "continuum.co"
  priority = 10
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_mx_3" {
  content  = "alt3.aspmx.l.google.com"
  name     = "continuum.co"
  priority = 10
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_mx_4" {
  content  = "alt2.aspmx.l.google.com"
  name     = "continuum.co"
  priority = 5
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_mx_5" {
  content  = "aspmx.l.google.com"
  name     = "continuum.co"
  priority = 1
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_aws_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "aws.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_aws_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "aws.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_dev_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "dev.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_dev_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "dev.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_dmarc_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "_dmarc.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_dmarc_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "_dmarc.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_domainkey_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "_domainkey.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_domainkey_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "_domainkey.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_e_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "e.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_e_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "e.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_email_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "email.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_email_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "email.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_info_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "info.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_info_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "info.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_k8s_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "k8s.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_k8s_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "k8s.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_mail_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "mail.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_mail_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "mail.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_news_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "news.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_news_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "news.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_newsletter_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "newsletter.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_newsletter_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "newsletter.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_ns1_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "ns1.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_ns1_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "ns1.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_ns2_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "ns2.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_ns2_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "ns2.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_spf_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "spf.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_spf_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "spf.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_test_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "test.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_test_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "test.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_track_ns_2" {
  content  = "ns02.cashparking.com"
  name     = "track.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_track_ns_1" {
  content  = "ns01.cashparking.com"
  name     = "track.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_spf" {
  content  = "v=spf1 -all"
  name     = "*.continuum.co"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_google_site_verification" {
  content  = "google-site-verification=rutK0TdrS-cOoFTQ1J5bYQnPJ-WR6pzSabIwNfg_dxk"
  name     = "continuum.co"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_spf_1" {
  content  = "v=spf1 -all"
  name     = "continuum.co"
  proxied  = false
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "continuum_co_webflow_verification" {
  content  = "one-time-verification=b38d533c-290d-44db-affd-5065dcfbd1bd"
  name     = "_webflow.continuum.co"
  proxied  = false
  ttl      = 300
  type     = "TXT"
  zone_id  = data.cloudflare_zone.continuum_co.zone_id
  settings = {}
}

