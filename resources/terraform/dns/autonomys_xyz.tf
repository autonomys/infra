resource "cloudflare_dns_record" "terraform_managed_resource_db2ccd228b09227cfcbe56dad03865bf_10" {
  content  = local.proxied_data.autonomys_xyz.root_0
  name     = "autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_75c9a47df80721404b46b87fce12fd58_11" {
  content  = local.proxied_data.autonomys_xyz.root_1
  name     = "autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_d00ce1ac97509fb6c83661473095d1a6_13" {
  content  = "162.159.152.4"
  name     = "blog.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_84830ebfc27e4dd33d19394648dd7f87_14" {
  content  = "162.159.153.4"
  name     = "blog.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_b4767669daa0f3c0fa1de7aec3e73771_22" {
  content  = "13.248.133.137"
  name     = "community.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_9653f8ed07c0583ebe3b0b967e8e3f4a_23" {
  content  = local.proxied_data.autonomys_xyz.demo_autodrive
  name     = "demo.auto-drive.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_7e1937606b6f23fb1ac12d89ac5f8ad7_24" {
  content  = local.proxied_data.autonomys_xyz.download_staging_autodrive
  name     = "download.staging.auto-drive.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_9997d854598a4a8076694b3e8eaf2c4c_25" {
  content  = local.proxied_data.autonomys_xyz.download_taurus_autodrive
  name     = "download.taurus.staging.auto-drive.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_9df0a22995207a238a5d29542f673c24_26" {
  content  = local.proxied_data.autonomys_xyz.explorer_evm_taurus_0
  name     = "evm.taurus.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_ed9af46ad8896073a743b2b2b77c67ef_27" {
  content  = local.proxied_data.autonomys_xyz.explorer_evm_mainnet
  name     = "explorer.auto-evm.mainnet.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_c965a1c24e4b34dbf3c472dd5e1591b0_28" {
  content  = local.proxied_data.autonomys_xyz.explorer_evm_taurus_1
  name     = "explorer.auto-evm.taurus.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_92f127ef97f5b12506012590be2b104a_29" {
  content  = "public.auto-drive.autonomys.xyz"
  name     = "gateway.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_aa9aaa1d72c4139dd87752dce4c94bed_30" {
  content  = local.proxied_data.autonomys_xyz.gateway_mainnet
  name     = "gateway.mainnet.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_ef15a6c580d75eab6f7d2ad443fb5be9_31" {
  content  = local.proxied_data.autonomys_xyz.gateway_staging
  name     = "gateway.staging.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_86f955bdca1337cdc0ec451edf101953_32" {
  content  = local.proxied_data.autonomys_xyz.gateway_taurus
  name     = "gateway.taurus.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_73ffd7d2c0111d8e2a7a0972ca263eae_33" {
  content  = local.proxied_data.autonomys_xyz.gateway_taurus_staging
  name     = "gateway.taurus.staging.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_6b86f143b41569d5715ed357cf1ea944_34" {
  content  = local.proxied_data.autonomys_xyz.grafana_evm_mainnet
  name     = "grafana.explorer.auto-evm.mainnet.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_dab0dbfdb22db0683e4d6fd53ba27cdc_35" {
  content  = local.proxied_data.autonomys_xyz.grafana_evm_taurus
  name     = "grafana.explorer.auto-evm.taurus.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_3070d116f3c08fa1a0d8a997c852aa6d_36" {
  content  = local.proxied_data.autonomys_xyz.indexer_mainnet
  name     = "indexer.mainnet.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_76ed9da0576917f810d7ff2ff3734c01_37" {
  content  = local.proxied_data.autonomys_xyz.indexer_staging
  name     = "indexer.staging.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_15196951933343ac7dfba7d152844302_38" {
  content  = local.proxied_data.autonomys_xyz.indexer_taurus
  name     = "indexer.taurus.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_63448b29744d9d7542f430915f9f4df6_39" {
  content  = local.proxied_data.autonomys_xyz.indexer_taurus_staging
  name     = "indexer.taurus.staging.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_2a444446e3153ebae375a41326582c23_40" {
  content  = local.proxied_data.autonomys_xyz.autodrive_mainnet
  name     = "mainnet.auto-drive.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_c537387f2cd9376569e24c76aa186979_41" {
  content  = local.proxied_data.autonomys_xyz.autodrive_public
  name     = "public.auto-drive.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_2d7a0d0117c649edf3f50cefc63d53cd_42" {
  content  = local.proxied_data.autonomys_xyz.autodrive_taurus_public
  name     = "public.taurus.auto-drive.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_565610ef1e10ab365a52ac67d77ea115_53" {
  content  = "15.204.73.119"
  name     = "scv.explorer.auto-evm.mainnet.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_5c2d6d05b0bed40ac962d18ff179838e_54" {
  content  = local.proxied_data.autonomys_xyz.scv_explorer_autodrive_taurus
  name     = "scv.explorer.auto-evm.taurus.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_b4647a2059431d6676c35ee056ca412e_55" {
  content  = local.proxied_data.autonomys_xyz.staging_autodrive
  name     = "staging.auto-drive.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_fe6a8dfc51847a21fa2d3a0fef0887dc_56" {
  content  = "15.204.73.119"
  name     = "stats.explorer.auto-evm.mainnet.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_388caee35817ab1f3cb8d13babe4ae2f_57" {
  content  = local.proxied_data.autonomys_xyz.stats_explorer_evm_taurus
  name     = "stats.explorer.auto-evm.taurus.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_1ec194881fa074ac7a6264227ed03e7f_58" {
  content  = local.proxied_data.autonomys_xyz.status
  name     = "status.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_095a86249dfb3454e80fc07e1a2f408b_59" {
  content  = local.proxied_data.autonomys_xyz.autodrive_taurus
  name     = "taurus.auto-drive.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_bbe3e3b3258956cc8bd7ca525b5c3cd9_60" {
  content  = local.proxied_data.autonomys_xyz.staging_taurus_autodrive
  name     = "taurus.staging.auto-drive.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_15fab5021f8bb0efe09d3d377860fcb7_61" {
  content  = local.proxied_data.autonomys_xyz.uptime
  name     = "uptime.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_1fee2425612ff63d655cde0a969c77df_69" {
  name    = "*.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CAA"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  data = {
    flags = 0
    tag   = "issue"
    value = "amazon.com"
  }
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_708c204128a5307a328c253bd80b8f85_70" {
  name    = "safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CAA"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  data = {
    flags = 0
    tag   = "issue"
    value = "amazon.com"
  }
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_f9213b98d281f714d5c24f6df9d38e0d_71" {
  name    = "*.staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CAA"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  data = {
    flags = 0
    tag   = "issue"
    value = "amazon.com"
  }
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_1ff06a1876c74865366b1d80024539ed_72" {
  name    = "staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CAA"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  data = {
    flags = 0
    tag   = "issue"
    value = "amazon.com"
  }
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_c2fd33b2c7f33a8c0a8d5bacd9e73528_73" {
  content = "_58716a844b97a4c99143680bca87b061.sdgjtdhdhz.acm-validations.aws"
  name    = "_0cb51155ee81f2362bd25953737affa9.staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_23f3dbb62074d6cdb7b10c03a64d1c35_74" {
  content = "_e005d46e6b63e60cd27883cb1aa573e6.sdgjtdhdhz.acm-validations.aws"
  name    = "_27e027657b943bc5de8249fa279f49df.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_14f5ca852646db91c6204ee563624f15_75" {
  content = "_dc672d34d26463f4682c6ac96eb18a8f.djqtsrsxkq.acm-validations.aws"
  name    = "_5865f51c06607c9ac81ce2703c39fcd8.community.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_49e42f93ea28215063342114ad19d184_76" {
  content = "6072.domainkey.u47499917.wl168.sendgrid.net"
  name    = "6072._domainkey.mail.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_7640a3ae2a9855f82d013cddd99ee368_77" {
  content = "607.domainkey.u47499917.wl168.sendgrid.net"
  name    = "607._domainkey.mail.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_91c16a305b9d81d8a3d49974803d0f15_78" {
  content = "a80ab473c4-hosting.gitbook.io"
  name    = "academy.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_4c4bcd92608c1d8a225bf51027bdab5d_79" {
  content = "d2ymdwbs6umczt.cloudfront.net"
  name    = "assets.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_af92c753a5b0f165df6c7b09aaf4168e_80" {
  content = "d1xizeqd8g84j.cloudfront.net"
  name    = "assets.staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_38a751222f27d5870ffc1f9c7a30737c_81" {
  content = "example.com"
  name    = "astral.autonomys.xyz"
  proxied = true
  tags    = []
  ttl     = 60
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_7ac4bbb0e6d9b17a36350ab39b2e36c8_83" {
  content = local.proxied_data.autonomys_xyz.bridge_mainnet
  name    = "bridge.mainnet.autonomys.xyz"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "bridge_chronos" {
  content = local.proxied_data.autonomys_xyz.bridge_chronos
  name    = "bridge.chronos.autonomys.xyz"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_a81077de846570742acece05d9f0c07b_85" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "config.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_9efb2992a3d5b36717753d972ff7c078_86" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "config.staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_cfe0f7cbfa8e8f9cefc2879c66cb9c3c_87" {
  content = "autonomysdevdocs.netlify.app"
  name    = "develop.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 60
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_16966bf4527a78a58e94e06248f34eaa_89" {
  content = "autonomys.github.io"
  name    = "docs.autonomys.xyz"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_2274de64333a08d3c6be3905bf6e2943_90" {
  content = "_domainconnect.gd.domaincontrol.com"
  name    = "_domainconnect.autonomys.xyz"
  proxied = true
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_70bd6e7782bb2edebc1564e32b22ce69_91" {
  content = "u47499917.wl168.sendgrid.net"
  name    = "em6407.mail.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_5dd5106fdaadac76bd8702f6c68b0d30_92" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "events.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_c935f1f7351156a457532622093b8b5c_93" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "events.staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_9191d14b877d18e8a7d3cd8890571c1b_94" {
  content = "example.com"
  name    = "explorer.autonomys.xyz"
  proxied = true
  tags    = []
  ttl     = 60
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_8a877b7d1fcdfc39385d30e1d9a47485_95" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "flower-transaction.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_b330bc71dca7982ddd03a804117fb10c_96" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "flower-transaction.staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_1e5884885d67114dd8261b4c0bcfb468_97" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "flower-transaction-testnet.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_081c0f0e9329719de4c8ebdcb9800704_98" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "flower-transaction-testnet.staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_de37f28cc4c83a8bff6c2b25adf161b1_99" {
  content = "subspace.hosted-by-discourse.com"
  name    = "forum.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_fd8ba77f2846cf294f64f3db5e116167_100" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "gateway.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_717c35bf5013c5686ab7a5e937156fc1_101" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "gateway.staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_60c94993c28154913741969735587024_102" {
  comment = "hubspot"
  content = "autonomys-xyz.hs16a.dkim.hubspotemail.net"
  name    = "hs1-49004947._domainkey.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_d962d20c3e1a237eb13663ec7c7c6f38_103" {
  comment = "hubspot"
  content = "autonomys-xyz.hs16b.dkim.hubspotemail.net"
  name    = "hs2-49004947._domainkey.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_b0e5b93075a0f4ba758b6d60f60cfd71_110" {
  content = "d5w1d4ch1mqvo.cloudfront.net"
  name    = "safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_67424e9aad9c9ac546ddda08b46cf960_111" {
  content = "shops.myshopify.com"
  name    = "shop.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_e01ba5050ef54ab1aaeb9c50ba03c8a2_112" {
  content = "d2r0ylf7cfvofa.cloudfront.net"
  name    = "staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_3a3b603e4d0a12bfc99d37a0dc407cfc_113" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "status.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_94b0a90d63d8882a725be9f557b4ad1b_114" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "transaction.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_acc9595d7710df297ac9ba284990eb83_115" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "transaction.staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_ccd372ab4b77ee2f7606a011235bd84b_116" {
  content = "safe-autonomys-1907842251.us-east-1.elb.amazonaws.com"
  name    = "transaction-testnet.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_702f1499bccd742bdb6e603b628bbd9c_117" {
  content = "safe-autonomys-1281125464.us-east-1.elb.amazonaws.com"
  name    = "transaction-testnet.staging.safe.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 1
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_55fcac1d820fb9064253f3dc23c1774c_118" {
  content = "proxy-ssl.webflow.com"
  name    = "www.autonomys.xyz"
  proxied = false
  tags    = []
  ttl     = 60
  type    = "CNAME"
  zone_id = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "terraform_managed_resource_6bb9825c6c1569b3cc64c21ca453db59_119" {
  content  = "smtp.google.com"
  name     = "autonomys.xyz"
  priority = 1
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "MX"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_405eee1b7f491a1d715eb4f107a83d93_120" {
  content  = "\"pE5pEkWSN2Wt8PG5HCbvBYzAbXLJE5efH-FvcLUrXAQ\""
  name     = "_acme-challenge.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_5785675def8b7ff141639ac3d110b6b7_121" {
  content  = "\"4KJnd49b33UwbegvmOds70oL_rXaqOu-KKX8yGGl-ao\""
  name     = "_acme-challenge.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_2c30aeb2439fdb662362f61d1279c397_122" {
  content  = "\"NusQ1Yc6dD0xcB2ZMsdrlrGjp_kx6cAOfQpbCm_XOzE\""
  name     = "_acme-challenge.blockscout.taurus.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_0f4a39be4908d12bf051a33482ecb4fe_123" {
  content  = "\"google-site-verification=hU8JVymNM0Yf8XQj9JmpBFnTxx4-ZnXQohpTSOwacxc\""
  name     = "autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_97f05d7e34b2e3ba465e04e6fc708cca_124" {
  content  = "\"google-site-verification=xzSWkbjOMZF3bAxpcZf93ipdMOK9ZxPQe4vbIRPj7ms\""
  name     = "autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_817025d489a51c5c09d18895f8473e63_125" {
  content  = "\"google-site-verification=i7PerGjpGY7R47iKJcOMtjpmfO2CnDhY0Y-kTKpwQA4\""
  name     = "autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_dfd1951fa90ac1700dd366371e848ebb_126" {
  content  = "\"v=spf1 include:_spf.google.com include:subspace.network include:49004947.spf07.hubspotemail.net -all\""
  name     = "autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_09b205e92a50d495407afe2b591fc05e_127" {
  content  = "\"57foN3YSwWdS6bvUsqRfztqw\""
  name     = "_beehiiv-authentication.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_bf7f1962dabb90d12d08e8c5b5f3e91e_128" {
  content  = "\"v=DMARC1; p=reject; pct=50; rua=mailto:admin@autonomys.xyz; ruf=mailto:admin@autonomys.xyz; aspf=r; adkim=r;\""
  name     = "_dmarc.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_97259ee2c7885cc7ba48272fb38e3426_129" {
  content  = "\"google-site-verification=lwfs2lbDfPFtUCI_n9OYfE7MR2XZAEkNjW4ByY2XaJA\""
  name     = "forum.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_025be3ed1a466bd62d301fff4b8f8387_130" {
  content  = "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA8YisTsvliHmkmCW0azbhWNVqmTha7IhxfWH61bC1fBM0kPMq1dMHecudzMQOAuahK3Hk/ISBVvj52xlCcvXXKa2SNn73G46IBXGTBH+CyQG1w8Z+2yPyH3jgsVboIuRI+lVAw766RP83miUO37ANFRwj207MtBXrfSEYWkIkc1s9y5rSBecN7GXqZxHzotydP\" \"cAfDPaw7PyFepVQoTndIdbU9rW7zlD4q61fMEyZH77ZVL3YmNVl1T63q6H8QJ/oXP12R9pKAuY4BRkRKPw4eNQv//y8HWIvKb5BIANjmE5G+nRKF92rzCKbpQ7fE8e8T270B3nZ9WSL0PVE4dqftQIDAQAB\""
  name     = "google._domainkey.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_19935fb38c7e16c6a72951f0b8da0980_131" {
  content  = "\"v=spf1 include:sendgrid.net -all\""
  name     = "mail.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_6c6a7ec604f5ccf07f5032c7a05c1d98_132" {
  content  = "\"one-time-verification=d54247a4-2baa-4dd9-89c2-2937c8d95924\""
  name     = "_webflow.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "terraform_managed_resource_6125859f850be53926a5a78daa829e85_133" {
  content  = "\"one-time-verification=848cabf6-7eb5-4311-ba69-ea99276afab4\""
  name     = "_webflow.www.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "TXT"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "staking_autonomys_xyz" {
  content  = "7d1c8898fca10668.vercel-dns-016.com"
  name     = "staking.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "CNAME"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "explorer_auto_evm_chronos" {
  content  = "15.204.31.207"
  name     = "explorer.auto-evm.chronos.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "stats_explorer_auto_evm_chronos" {
  content  = "15.204.31.207"
  name     = "stats.explorer.auto-evm.chronos.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "scv_explorer_auto_evm_chronos" {
  content  = "15.204.31.207"
  name     = "scv.explorer.auto-evm.chronos.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "grafana_explorer_auto_evm_chronos" {
  content  = "15.204.31.207"
  name     = "grafana.explorer.auto-evm.chronos.autonomys.xyz"
  proxied  = false
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}

resource "cloudflare_dns_record" "subql_staking_autonomys_xyz" {
  content  = "18.220.135.20"
  name     = "subql.staking.mainnet.autonomys.xyz"
  proxied  = true
  tags     = []
  ttl      = 1
  type     = "A"
  zone_id  = data.cloudflare_zone.autonomys_xyz.zone_id
  settings = {}
}