# The private mesh between the staging hosts. Mesh addresses are private and
# fixed per role; endpoints and public keys come from tfvars.
locals {
  mesh_port   = 51820
  mesh_subnet = "10.77.0.0/24"
  mesh_hosts = {
    services      = { endpoint = var.services_host_ipv4, address = "10.77.0.10" }
    files-gateway = { endpoint = var.gateway_host_ipv4, address = "10.77.0.20" }
    public        = { endpoint = var.public_host_ipv4, address = "10.77.0.30" }
  }

  mesh = {
    for name, host in local.mesh_hosts : name => {
      address = host.address
      subnet  = local.mesh_subnet
      port    = local.mesh_port
      peers = [
        for peer, p in local.mesh_hosts : {
          name       = peer
          endpoint   = p.endpoint
          address    = p.address
          public_key = lookup(var.mesh_public_keys, peer, "")
        } if peer != name
      ]
    }
  }
}

module "files_gateway" {
  source = "../../../modules/auto-drive-gateway-host"

  deployer = {
    ssh_user           = "ubuntu"
    ssh_agent_identity = var.ssh_agent_identity
    path_to_scripts    = "../../../scripts"
  }

  host = {
    ipv4     = var.gateway_host_ipv4
    hostname = "auto-drive-files-gateway-chronos"
  }

  network_id             = "chronos"
  create_object_mappings = "yes"

  images = {
    node = "ghcr.io/autonomys/node:mainnet-2026-jan-20"
  }

  mesh = local.mesh["files-gateway"]
}

module "services" {
  source = "../../../modules/auto-drive-services-host"

  deployer = {
    ssh_user           = "ubuntu"
    ssh_agent_identity = var.ssh_agent_identity
    path_to_scripts    = "../../../scripts"
  }

  host = {
    ipv4     = var.services_host_ipv4
    hostname = "auto-drive-staging-services"
  }

  mesh = local.mesh["services"]

  # the versions production runs
  images = {
    postgres = "postgres:17.9-bookworm"
    rabbitmq = "rabbitmq:3.13.7-management"
  }

  # Sized for a 64 GB box; see the README's services section
  postgres = {
    databases        = ["gateway"]
    memory_limit_gib = 32
    shm_size_gib     = 2
    settings = {
      shared_buffers           = "8GB"
      effective_cache_size     = "24GB"
      work_mem                 = "32MB"
      maintenance_work_mem     = "1GB"
      max_connections          = "300"
      max_wal_size             = "4GB"
      random_page_cost         = "1.1"
      effective_io_concurrency = "200"
    }
  }
  postgres_password = var.postgres_password

  rabbitmq = {
    memory_limit_gib = 4
  }
  rabbitmq_username = var.rabbitmq_username
  rabbitmq_password = var.rabbitmq_password
}

locals {
  services_address = local.mesh_hosts.services.address
  database_url     = "postgres://postgres:${var.postgres_password}@${local.services_address}:5432/postgres"
  rabbitmq_url     = "amqp://${var.rabbitmq_username}:${var.rabbitmq_password}@${local.services_address}:5672"

  # Production's public backend settings, with Chronos and staging values in
  # place of mainnet's
  backend_settings = {
    NODE_ENV               = "production"
    OPTIONAL_AUTH          = "true"
    CORS_ALLOWED_ORIGINS   = ""
    FORBIDDEN_EXTENSIONS   = "exe,bin"
    STAFF_DOMAINS          = "@autonomys.xyz,@subspace.network"
    METRIC_ENVIRONMENT_TAG = "staging"
    VICTORIA_ACTIVE        = "true"
    VICTORIA_ENDPOINT      = "https://vmetrics.subspace.network"
    VICTORIA_USERNAME      = var.victoria_username
    EVM_CHAIN_ID           = "8700"
    # payments are off on the public backend; the address only has to be valid
    EVM_CHAIN_CONTRACT_ADDRESS = "0x0000000000000000000000000000000000000000"
  }

  # the files gateway's indexer and file retriever, over the mesh
  backend_endpoints = {
    object_mapping_archiver = "ws://${local.mesh_hosts["files-gateway"].address}:3000/ws"
    files_gateway           = "http://${local.mesh_hosts["files-gateway"].address}:8090"
    auth_service            = "https://auth.staging.auto-drive.autonomys.xyz"
    evm_chain               = "https://auto-evm.chronos.autonomys.xyz/ws"
  }
}

module "public" {
  source = "../../../modules/auto-drive-backend-host"

  deployer = {
    ssh_user           = "ubuntu"
    ssh_agent_identity = var.ssh_agent_identity
    path_to_scripts    = "../../../scripts"
  }

  host = {
    ipv4     = var.public_host_ipv4
    hostname = "auto-drive-staging-public"
  }

  mesh = local.mesh["public"]

  # production's public host's COMPOSE_PROFILES: Hasura, and the download API and worker
  profiles = ["base", "download"]

  # what production ran on 2026-11-12, so upgrades are rehearsed here first; the
  # backend tag is the commit the module's compose file mirrors
  images = {
    backend = "ghcr.io/autonomys/auto-drive-backend:99e753be@sha256:78288688bf82fd87101eea25bed789410ef4ade33085978432dc91df0d7d80d2"
    hasura  = "hasura/graphql-engine:v2.40.0.cli-migrations-v3@sha256:68b16a019e4f6f3136fb09ef26a934c718e3ff74eab76d52244abccb8fd80b55"
  }

  run_migrations = true
  database_url   = local.database_url
  rabbitmq_url   = local.rabbitmq_url
  # the services deploy sets the passwords these URLs carry
  wait_for = [module.services.deploy_id]

  endpoints = merge(local.backend_endpoints, {
    rpc = "wss://rpc-0.chronos.autonomys.xyz/ws"
  })

  settings = merge(local.backend_settings, {
    ALL_SERVICES_ACTIVE = "false"
    API_DESCRIPTION_URL = "https://public.staging.auto-drive.autonomys.xyz/api/docs/raw"
  })

  secrets = {
    auth_service_api_key = var.auth_service_api_key
    files_gateway_token  = var.files_gateway_token
    extra = merge(
      { VICTORIA_PASSWORD = var.victoria_password },
      var.slack_webhook_url == "" ? {} : { SLACK_WEBHOOK_URL = var.slack_webhook_url },
    )
  }

  hasura_admin_secret = var.hasura_admin_secret
  hasura = {
    jwt_public_key = var.hasura_jwt_public_key
    enable_console = true
  }

  ingress = {
    site = "public"
    hostnames = {
      app     = "public.staging.auto-drive.autonomys.xyz"
      s3      = "s3.staging.auto-drive.autonomys.xyz"
      gateway = "gateway.staging.autonomys.xyz"
    }
    letsencrypt = {
      email = "admin@autonomys.xyz"
    }
  }
}
