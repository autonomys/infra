module "cloudflare_lb_gemini" {
  source = "../cloudflare_lb_module"

  domain               = var.domain
  network              = var.network
  zone_id              = var.zone_id
  account_id           = var.account_id
  cloudflare_api_token = var.cloudflare_api_token

  records = [
    {
      name     = "${var.rpc_prefix}-0",
      hostname = "${var.rpc_prefix}-0.${var.network}.${var.domain}",
      value    = "52.91.27.239",
      type     = "A",
      tags     = ["rpc", "us"]
    },
    {
      name     = "${var.rpc_prefix}-1",
      hostname = "${var.rpc_prefix}-1.${var.network}.${var.domain}",
      value    = "65.108.232.52",
      type     = "A",
      tags     = ["rpc", "eu"]
    },
    {
      name     = "${var.domain_prefix}-0",
      hostname = "${var.domain_prefix}-3.evm.${var.network}.${var.domain}",
      value    = "174.129.202.104",
      type     = "A",
      tags     = ["evm", "us"]
    },
    {
      name     = "${var.domain_prefix}-3",
      hostname = "${var.domain_prefix}-3.evm.${var.network}.${var.domain}",
      value    = "65.108.228.84",
      type     = "A",
      tags     = ["evm", "eu"]
    },
  ]

  monitors = [
    {
      name           = "rpc",
      expected_codes = "2xx",
      timeout        = 5,
      interval       = 60,
      retries        = 2,
      port           = 30333,
      description    = "RPC Monitor"
    },
    {
      name           = "evm",
      expected_codes = "2xx",
      timeout        = 5,
      interval       = 60,
      retries        = 2,
      port           = 30333,
      description    = "EVM Domain Monitor"
    },
  ]

  load_balancers = [
    {
      name        = "rpc",
      description = "Load Balancer for RPC nodes"
    },
    {
      name        = "evm",
      description = "Load Balancer for EVM Domain nodes"
    },
  ]
}
