data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

// subspace blog
resource "cloudflare_record" "blog_0" {
  comment = "Medium .blog Redirect #2"
  name    = "blog"
  proxied = false
  ttl     = 3600
  type    = "A"
  value   = "162.159.152.4"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "blog_1" {
  comment = "Medium .blog Redirect #1"
  name    = "blog"
  proxied = false
  ttl     = 3600
  type    = "A"
  value   = "162.159.153.4"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

// subspace docs
resource "cloudflare_record" "docs" {
  name    = "docs"
  comment = "Redirected docs to Github"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "subspace.github.io"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

// subspace forum
resource "cloudflare_record" "forum" {
  name    = "forum"
  comment = "Subspace's discourse forum"
  proxied = false
  ttl     = 60
  type    = "CNAME"
  value   = "subspace.hosted-by-discourse.com"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

// subspace status page
resource "cloudflare_record" "status" {
  comment = "Status redirect"
  name    = "status"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "subspace.github.io"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

// subspace block explorer
resource "cloudflare_record" "block_explorer" {
  comment = "Subspace block explorer"
  name    = "explorer"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "subspace.github.io"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

// TODO: the following records needs to be updated with further info on why they exist
resource "cloudflare_record" "terraform_managed_resource_964bf73d0853cefc64803baef62167a5" {
  name    = "ws"
  proxied = true
  ttl     = 1
  type    = "A"
  value   = "65.108.232.54"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_e59b1773ac2b8ecbff7999562a42e8f9" {
  name    = "em1673"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "u27463899.wl150.sendgrid.net"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_55771960964e20edcd05f5319f7b7b63" {
  name    = "farm-rpc"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "aries-farm-rpc-b.subspace.network"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_8c34fb58ccc82ccee8a5aa916c6aee55" {
  name    = "k2._domainkey"
  proxied = false
  ttl     = 60
  type    = "CNAME"
  value   = "dkim2.mcsv.net"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_8c342db13e3ca5d4c407a5cc8a056f84" {
  name    = "k3._domainkey"
  proxied = false
  ttl     = 60
  type    = "CNAME"
  value   = "dkim3.mcsv.net"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_c6c12f1cafaa086ec24e5d3538b08aef" {
  name    = "nfthack-2022"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "subspace.network"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_f62094c6234d9f68bcd933a0f47d3d64" {
  name    = "pages"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "dns1.p08.nsone.net"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_0082afc8518c5c691215b445f53c6654" {
  name    = "ru"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "websites.weglot.com"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_83bbe72d68962e5c6102f1f6118cb626" {
  name    = "s1._domainkey"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "s1.domainkey.u27463899.wl150.sendgrid.net"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_e7d319fe6cdb95b5ead29b78f9f25063" {
  name    = "s2._domainkey"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "s2.domainkey.u27463899.wl150.sendgrid.net"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_409a596793c8d298ec5ebdfecbb111e7" {
  name    = "subspace.network"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "proxy-ssl.webflow.com"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_31b86be89143160021c6bd9afdaf83b3" {
  name    = "tauri-updater"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "subspace.network"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_b80fc952b5d2edbf7843fdfc91762d56" {
  name    = "testnet-relayer"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "subspace.network"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_88801c0aa1969b1b05af21ae13b0f922" {
  name    = "test-rpc"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "aries-test-rpc-a.subspace.network"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_1b1accbe56b4fc84e9f57ba3737ec88c" {
  name    = "tr"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "websites.weglot.com"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_3c4892d732cd9598d969e23b98fe8e29" {
  name    = "uk"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "websites.weglot.com"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_113772a997574a65548468b238009d49" {
  name    = "vi"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "websites.weglot.com"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_a50726853ab98cd0a23b0d67f69a62ba" {
  name    = "www"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "proxy-ssl.webflow.com"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_f28701c7b10678abc190c13b5906dbe1" {
  name    = "zh"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "websites.weglot.com"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_d5b9ae2a99064d91811927a96fda5d57" {
  name    = "_smtp._tls"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=TLSRPTv1; rua=mailto:g5oqy2di@tls.us.dmarcian.com"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_6aa9914d5ed8da851e945e032178034c" {
  name    = "subspace.network"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "google-site-verification=f2RfDFH2l59GizXR0tKkIZ2i-M1LZjFFb-KG1dW61VM"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_602bacb1de51c879deb6224bf816d853" {
  name    = "subspace.network"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "google-site-verification=rSM4tCtwIT6_GKtHdpeRqUFSY3UQRzPuMe7qXc6OH8A"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_61eda5c4af93ca9d0f50e2fe1b56ae6d" {
  name    = "subspace.network"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "google-site-verification=Fxi1PlaR_c4E2l34q5G5QoiMPc7PeRqY_sLpD4XiAxg"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}
