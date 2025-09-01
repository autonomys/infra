resource "cloudflare_dns_record" "terraform_managed_resource_5bf77b8c267708134d3b317fd04011f1_12" {
  content  = local.proxied_data.subspace_network.blog
  name     = "blog.subspace.network"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_f286f281d635bef7116ef6bf80cfbf68_29" {
  comment  = "The Graph Dashboard"
  content  = "65.108.74.115"
  name     = "dashboard.thegraph.subspace.network"
  proxied  = false
  tags     = ["graph"]
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_449eb8c2974ef1a907cdecc5e02072a5_40" {
  content  = local.proxied_data.subspace_network.grafana
  name     = "grafana.subspace.network"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_000bcfcfb0fa47d7871f9edd39e388fc_41" {
  content  = local.proxied_data.subspace_network.vmetrics_grafana
  name     = "grafana.vmetrics.subspace.network"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_54ba6b98fe500b904254de740edca8bc_42" {
  content  = local.proxied_data.subspace_network.logging
  name     = "logging.subspace.network"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_12970131055914651136f24f4121e363_50" {
  content  = local.proxied_data.subspace_network.status
  name     = "status.subspace.network"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_d3499a5d8eca7a37550cfd5fe93a1390_57" {
  content  = local.proxied_data.subspace_network.substation
  name     = "substation.subspace.network"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_ba3088cfa6a2bd654c300bdb305d33d6_58" {
  content  = "44.244.168.0"
  name     = "telemetry.subspace.network"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_9153792f008c3810b59df7cd6bfa94c4_59" {
  content  = local.proxied_data.subspace_network.uptime
  name     = "uptime.subspace.network"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_e28c69a6fb64d3f23bd910adea7bf11b_60" {
  content  = local.proxied_data.subspace_network.vmetrics
  name     = "vmetrics.subspace.network"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_125b8055d70e7ab63d76e57c66010372_73" {
  name    = "*.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CAA"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  data = {
    flags = 0
    tag   = "issue"
    value = "amazon.com"
  }
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_4f2ca51e2c60ad98a8d6b6fb52cd1e15_74" {
  name    = "safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CAA"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  data = {
    flags = 0
    tag   = "issue"
    value = "amazon.com"
  }
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_9041b838b1cb52817389c56c3f89e595_75" {
  name    = "*.staging.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CAA"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  data = {
    flags = 0
    tag   = "issue"
    value = " amazon.com"
  }
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_5da4edf69d3314cbf93b51cd29f2cf3f_76" {
  name    = "staging.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CAA"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  data = {
    flags = 0
    tag   = "issue"
    value = "amazon.com"
  }
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_1b0ec8a6a4ee55a22431ffcafe35e930_77" {
  comment = "Gnosis safe wallet record"
  content = "_380a105b62d8d1fad6ff4eab53bed3b1.sdgjtdhdhz.acm-validations.aws"
  name    = "_545cdcc01799562c77704ee832f7d8a7.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_bbf07144f8e2e293eaa018fa615632b4_79" {
  content = "d2ymdwbs6umczt.cloudfront.net"
  name    = "assets.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_c24f0e69f62f1a93043d353d809133d2_80" {
  content = "d1xizeqd8g84j.cloudfront.net"
  name    = "assets.staging.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_c22cbbb2e4544865024de69eb56f76de_81" {
  content = local.proxied_data.subspace_network.astral
  name    = "astral.subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_bedb0568eb97ee720a4943f7f6752b96_82" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "config.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_ad6531dc7af1af15a45a2f228fbf68fa_83" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "config.staging.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_178195fec92642e3753e2a9486e76330_84" {
  comment = "Gnosis safe wallet record"
  content = "_856ebe9dc2713084429ac68052f91ff1.sdgjtdhdhz.acm-validations.aws"
  name    = "_df2aaa75112b475f13612c9c94d3c70f.staging.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_bc72c7a9dfb4ca3a456c6357213a025b_85" {
  comment = "Redirected docs to Github"
  content = "subspace.github.io"
  name    = "docs.subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_e59b1773ac2b8ecbff7999562a42e8f9_86" {
  content = "u27463899.wl150.sendgrid.net"
  name    = "em1673.subspace.network"
  proxied = false
  tags    = []
  ttl     = 3600
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_45e9fd553cbd5b2e16dc35d84bae7fc3_87" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "events.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_4c29ce72e497285e7a2a4d392f118377_88" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "events.staging.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_d7fe4b7f192cf9eca21bbc1a50089742_89" {
  comment = "Subspace block explorer"
  content = local.proxied_data.subspace_network.explorer
  name    = "explorer.subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_2fbaf4a20fe262c830fd62868df3fc01_91" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "flower-transaction-testnet.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_b1306bccfba8d6f4dd040307da1070b9_92" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "flower-transaction-testnet.staging.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_01ccb25815933fc11631b3a0a288b536_93" {
  comment = "Subspace's discourse forum"
  content = "subspace.hosted-by-discourse.com"
  name    = "forum.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_83cfedda34e89ec6869d2471234e7ac9_94" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "gateway.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_88566e4d221a49b39352c76f4c647f6c_95" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "gateway.staging.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_8c34fb58ccc82ccee8a5aa916c6aee55_96" {
  content = "dkim2.mcsv.net"
  name    = "k2._domainkey.subspace.network"
  proxied = false
  tags    = []
  ttl     = 60
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_8c342db13e3ca5d4c407a5cc8a056f84_97" {
  content = "dkim3.mcsv.net"
  name    = "k3._domainkey.subspace.network"
  proxied = false
  tags    = []
  ttl     = 60
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_ebbd29f13543b6c8f9b0be7be397065d_98" {
  content = "subspace.network"
  name    = "mail.subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_c6c12f1cafaa086ec24e5d3538b08aef_99" {
  content = "subspace.network"
  name    = "nfthack-2022.subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_f62094c6234d9f68bcd933a0f47d3d64_100" {
  content = local.proxied_data.subspace_network.pages
  name    = "pages.subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_0082afc8518c5c691215b445f53c6654_101" {
  content = "websites.weglot.com"
  name    = "ru.subspace.network"
  proxied = false
  tags    = []
  ttl     = 3600
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_83bbe72d68962e5c6102f1f6118cb626_102" {
  content = "s1.domainkey.u27463899.wl150.sendgrid.net"
  name    = "s1._domainkey.subspace.network"
  proxied = false
  tags    = []
  ttl     = 3600
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_e7d319fe6cdb95b5ead29b78f9f25063_103" {
  content = "s2.domainkey.u27463899.wl150.sendgrid.net"
  name    = "s2._domainkey.subspace.network"
  proxied = false
  tags    = []
  ttl     = 3600
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_c99b837e6bae1efc2cc23369c165b42f_104" {
  content = "d5w1d4ch1mqvo.cloudfront.net"
  name    = "safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_2a4ff4c30438d6210bf22df87cca89a0_105" {
  content = "d2r0ylf7cfvofa.cloudfront.net"
  name    = "staging.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_98a2cb7787a411ac8210e2611849c25e_106" {
  content = "public.r2.dev"
  name    = "static.r2.subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_14d5ac1d4ca05a7c752185bb5e7e12b2_107" {
  content = "stats.uptimerobot.com"
  name    = "status.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_6b0245b52515f1e4dd64761cb16017bd_108" {
  comment = "Redirected subnomicon to Github"
  content = "subspace.github.io"
  name    = "subnomicon.subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_409a596793c8d298ec5ebdfecbb111e7_109" {
  content = "autonomys.xyz"
  name    = "subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_31b86be89143160021c6bd9afdaf83b3_110" {
  content = "subspace.network"
  name    = "tauri-updater.subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_c1eb63c4b718e3b09da91dbf50c52019_113" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "transaction-testnet.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_157551ecd05854dc1af9e14dca8f404e_114" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "transaction-testnet.staging.safe.subspace.network"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_1b1accbe56b4fc84e9f57ba3737ec88c_115" {
  content = "websites.weglot.com"
  name    = "tr.subspace.network"
  proxied = false
  tags    = []
  ttl     = 3600
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_3c4892d732cd9598d969e23b98fe8e29_116" {
  content = "websites.weglot.com"
  name    = "uk.subspace.network"
  proxied = false
  tags    = []
  ttl     = 3600
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_113772a997574a65548468b238009d49_117" {
  content = "websites.weglot.com"
  name    = "vi.subspace.network"
  proxied = false
  tags    = []
  ttl     = 3600
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_a50726853ab98cd0a23b0d67f69a62ba_118" {
  content = "autonomys.xyz"
  name    = "www.subspace.network"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_f28701c7b10678abc190c13b5906dbe1_119" {
  content = "websites.weglot.com"
  name    = "zh.subspace.network"
  proxied = false
  tags    = []
  ttl     = 3600
  type    = "CNAME"
  zone_id = data.cloudflare_zone.subspace_network.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_dab7cd1a64e7cb2425777cfcae662970_120" {
  comment  = "MX record pointing to our preferred mailserver"
  content  = "aspmx.l.google.com"
  name     = "subspace.network"
  priority = 1
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_85749528eecf56ddfa45e31ffcc6cb98_121" {
  comment  = "MX record pointing to our preferred mailserver"
  content  = "alt3.aspmx.l.google.com"
  name     = "subspace.network"
  priority = 10
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_eccb58642a3790718486652ad434eb6a_122" {
  comment  = "MX record pointing to our preferred mailserver"
  content  = "alt4.aspmx.l.google.com"
  name     = "subspace.network"
  priority = 10
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_135320e237f1306ac9e772689fe915d8_123" {
  comment  = "MX record pointing to our preferred mailserver"
  content  = "alt1.aspmx.l.google.com"
  name     = "subspace.network"
  priority = 5
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_cefa080d15704bc3c3c47f5a715c9c4d_124" {
  comment  = "MX record pointing to our preferred mailserver"
  content  = "alt2.aspmx.l.google.com"
  name     = "subspace.network"
  priority = 5
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "MX"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_904bcb2f54aca3f0e3fb9da47b6276da_125" {
  content  = "ns-576.awsdns-08.net"
  name     = "eks.subspace.network"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_faa68a5c6ce917c264ed178ca6133a49_126" {
  content  = "ns-212.awsdns-26.com"
  name     = "eks.subspace.network"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_b46ad2efe1cd0cb076162edf45329651_127" {
  content  = "ns-1316.awsdns-36.org"
  name     = "eks.subspace.network"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_a3bc94defdba8f366a36137257531be2_128" {
  content  = "ns-1549.awsdns-01.co.uk"
  name     = "eks.subspace.network"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "NS"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_64fbcb12a235bf0581b2200a2b277788_129" {
  content  = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\""
  name     = "cf2024-1._domainkey.subspace.network"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_0e827191051aeda7ec739f6e5b9c994a_130" {
  comment  = "DMARC for communications"
  content  = "\"v=DMARC1; p=reject; pct=100; rua=mailto:g5oqy2di@ag.dmarcian.com, mailto:admin@subspace.network; ruf=mailto:admin@subspace.network; aspf=r; adkim=r;\""
  name     = "_dmarc.subspace.network"
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_f1b7884094d05de6a0035a5ff51da125_131" {
  comment  = "DKIM for mail specific to Gmail"
  content  = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDLnilf99usHi/O15XFY20VXwoy0NrX5w0dsDXBhf8kd+KErra7ue7oxXYK8eLG4Joq7y8UY7oHzQPINsrYcjlnwkx2/GRSgXFmlIcSiCbF2mKCtDPNKdtyRl1zKoiOLl8KMdRKe+MY7OYhRhgq4B83KeCsBPm09QBbub1CMq+PlwIDAQAB"
  name     = "google._domainkey.subspace.network"
  proxied  = false
  tags     = []
  ttl      = 60
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_d5b9ae2a99064d91811927a96fda5d57_132" {
  content  = "v=TLSRPTv1; rua=mailto:g5oqy2di@tls.us.dmarcian.com"
  name     = "_smtp._tls.subspace.network"
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_04cbeca369cba55c519846fe394dfd6b_133" {
  comment  = "SPF record"
  content  = "\"v=spf1 include:_spf.google.com -all\""
  name     = "subspace.network"
  proxied  = false
  tags     = []
  ttl      = 60
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_89df94041188716a4aa454e44d27e624_134" {
  content  = "google-site-verification=8IMDatUy7YOTr78VEtiNhzMZmYJHfwoDF8VVVEKoYn4"
  name     = "subspace.network"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_f7c5ddccda0c13a7865e87e7613efab1_135" {
  comment  = "WalletConnect verification for blockscout"
  content  = "ab6614dc-f6aa-46e1-af0a-012bd572d970=b4bd4f5b573bdfd58139ca70168d95a2505018088e8121554b6df17f8bad7e0d"
  name     = "subspace.network"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_37b17a8e2732c2fe53b2e220ac7c282e_136" {
  content  = "MS=ms69982775"
  name     = "subspace.network"
  proxied  = false
  tags     = ["microsoft"]
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_602bacb1de51c879deb6224bf816d853_137" {
  content  = "google-site-verification=rSM4tCtwIT6_GKtHdpeRqUFSY3UQRzPuMe7qXc6OH8A"
  name     = "subspace.network"
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_61eda5c4af93ca9d0f50e2fe1b56ae6d_138" {
  content  = "google-site-verification=Fxi1PlaR_c4E2l34q5G5QoiMPc7PeRqY_sLpD4XiAxg"
  name     = "subspace.network"
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_6aa9914d5ed8da851e945e032178034c_139" {
  content  = "google-site-verification=f2RfDFH2l59GizXR0tKkIZ2i-M1LZjFFb-KG1dW61VM"
  name     = "subspace.network"
  proxied  = false
  tags     = []
  ttl      = 3600
  type     = "TXT"
  zone_id  = data.cloudflare_zone.subspace_network.zone_id
  settings = {}
}

