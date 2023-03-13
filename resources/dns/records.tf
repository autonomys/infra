data "cloudflare_zone" "cloudflare_zone" {
  name = "subspace.network"
}

resource "cloudflare_record" "terraform_managed_resource_a5918aae5b19597735cebd0887f1f22a" {
  comment = "Medium .blog Redirect #2"
  name    = "blog"
  proxied = false
  ttl     = 3600
  type    = "A"
  value   = "162.159.152.4"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_d9ea02136ac010af87ef824e749eea73" {
  comment = "Medium .blog Redirect #1"
  name    = "blog"
  proxied = false
  ttl     = 3600
  type    = "A"
  value   = "162.159.153.4"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_964bf73d0853cefc64803baef62167a5" {
  name    = "ws"
  proxied = true
  ttl     = 1
  type    = "A"
  value   = "65.108.232.54"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_f96e5d357fde19cd4352c9992de01e23" {
  name    = "docs"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "subspace.github.io"
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

resource "cloudflare_record" "terraform_managed_resource_785c947c74154dd6d3c13f1bc14ef9ed" {
  name    = "forum"
  proxied = false
  ttl     = 60
  type    = "CNAME"
  value   = "subspace.hosted-by-discourse.com"
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

resource "cloudflare_record" "terraform_managed_resource_1844a4529de1350925ab918618b13c83" {
  name    = "mail"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  value   = "subspace.network"
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

resource "cloudflare_record" "terraform_managed_resource_452fc18259863878b1842fd5c0b19146" {
  comment = "Status Redirect"
  name    = "status"
  proxied = false
  ttl     = 3600
  type    = "CNAME"
  value   = "subspace.github.io"
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

resource "cloudflare_record" "terraform_managed_resource_f2ba964c8308b5da6a6977eb8a053c98" {
  name     = "subspace.network"
  priority = 5
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt1.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_fee42bf9a1798e7e80cfe91222f6484e" {
  name     = "subspace.network"
  priority = 5
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt2.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_d381ec393946a0115b8e4de48c7cf7d3" {
  name     = "subspace.network"
  priority = 10
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt4.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_19d853415853f88f816d0e31d5b8c4e8" {
  name     = "subspace.network"
  priority = 1
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_e0e0314943ceadf7b86e7dd0c1ab63b8" {
  name     = "subspace.network"
  priority = 10
  proxied  = false
  ttl      = 3600
  type     = "MX"
  value    = "alt3.aspmx.l.google.com"
  zone_id  = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_cb2914cda5a9ff1c86179f0dbd45aa0a" {
  name    = "default._domainkey"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7zwrsOLB+eJ9SG1t7+OwOT2BuacTImFHozl8I/ mypg7rhtp4i1NpkSnjjDC3FdXXiUhsHTvAUvg5nMtGp3nCwwQYna0C8Jo7dbt3+NUVLj9KCBBBegxPS/WoJghPSbiKq4T/SBdM0K ShrVn7C/1blWA+N4XxOwmVtELV8POMwRYCzlrxCi3kdjbRY+4gXYKmcc7MSRi5ubyR7P/+K1/CkLbJa1SbxdS6/zMRIzPH/6vOR6 be1Qkw5PFsYu0gYbz3QDqYxaUTS3euWSPE3uLnPQEgAryX3SlKQB8uyjNbxF86ukslwwe9Q5cCZ1UPsl/89qcBRirnJbfoGlwb5j rX3QIDAQAB;"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_4143783454a628a5d442a3073e8d8257" {
  name    = "_dmarc"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=DMARC1; p=reject; pct=100; rua=mailto:g5oqy2di@ag.dmarcian.com, mailto:admin@subspace.network; ruf=mailto:admin@subspace.network"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_0fa753e60de27ab86a5683d144455364" {
  name    = "_domainkey"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=DKIM1; o=~"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}

resource "cloudflare_record" "terraform_managed_resource_4465f47bd1fcbb6c6850c5c84577b07e" {
  name    = "google._domainkey"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyqbz3f5O6pOl9LK3zOmKkczcK9aCdB34tSzDkA ZRD0g+OtBhlyWyzNeQGsrVianIfM9xyfZ7MVJK7sB/VGKIFIe5glb/Lh9tf/kLCRbkOnaafiXP5tOk4DC+mBpHOjyT0GgX5x4hxg oLmeJOrRLSu1niPQY/VqMtNsYa9+gAIo0YZnZeNi2w3FjWaslm5F7uI6mISdH3HZchqhzx2E6Ct+VJhLM0Ir+6v3qV5ylArtJzc+ PoTGdk65n5oq+Ioj9oTK4VmJunZ6jaU2Vimo+2TTAhBtRWQCa8Xy15/3kVZXiKJ4ddtPDnzSEval4er4SksIhtVYaxkeanU7pGbK w1SQIDAQAB"
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

resource "cloudflare_record" "terraform_managed_resource_12997d2641e54e3226780f31597a7782" {
  name    = "subspace.network"
  proxied = false
  ttl     = 3600
  type    = "TXT"
  value   = "v=spf1 +a +a:ns1.us145.siteground.us include:_spf.google.com +mx ~all"
  zone_id = data.cloudflare_zone.cloudflare_zone.id
}
