# The private mesh between the staging hosts. Mesh addresses are private and
# fixed per role; endpoints and public keys come from tfvars.
locals {
  mesh_port   = 51820
  mesh_subnet = "10.77.0.0/24"
  mesh_hosts = {
    services      = { endpoint = var.services_host_ipv4, address = "10.77.0.10" }
    files-gateway = { endpoint = var.gateway_host_ipv4, address = "10.77.0.20" }
    public        = { endpoint = var.public_host_ipv4, address = "10.77.0.30" }
    private       = { endpoint = var.private_host_ipv4, address = "10.77.0.40" }
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

  # The apps are a prerelease build of autonomys/auto-files-gateway#218's head,
  # whose migrations run on an empty database. Move them to the merge commit's
  # tag once it merges, as main's builds are tagged with their commit.
  images = {
    node                   = "ghcr.io/autonomys/node:mainnet-2026-jan-20"
    gateway                = "ghcr.io/autonomys/gateway:mainnet-2026-oct-22"
    object_mapping_indexer = "ghcr.io/autonomys/object-mapping-indexer:snapshot-9f2f2c66@sha256:c5eacd88cdbea3705aef0538fc7c4a7a567e3059616ad0d683ecee707798fec5"
    file_retriever         = "ghcr.io/autonomys/file-retriever:snapshot-9f2f2c66@sha256:8e5c1dd70789835df442284f0f214f862135caf1fde980b4d86f9c8e93771372"
  }

  database = {
    host = local.mesh_hosts.services.address
    name = "gateway"
    user = "postgres"
  }
  database_password = var.postgres_password
  api_secret        = var.files_gateway_token
  # the services deploy sets that password, so the migrations follow it
  wait_for    = [module.services.deploy_id]
  database_id = local.services_database_id

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
    databases        = ["auth", "gateway"]
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
  services_address  = local.mesh_hosts.services.address
  database_url      = "postgres://postgres:${var.postgres_password}@${local.services_address}:5432/postgres"
  auth_database_url = "postgres://postgres:${var.postgres_password}@${local.services_address}:5432/auth"
  rabbitmq_url      = "amqp://${var.rabbitmq_username}:${var.rabbitmq_password}@${local.services_address}:5672"

  # Changes when the services host is rebuilt, and with it its databases: the
  # mesh key is generated only on a fresh install, so a bootstrap that re-runs
  # over the live host, for an installer.sh change say, keeps it
  services_database_id = sha1(lookup(var.mesh_public_keys, "services", ""))

  # what production ran on 2026-11-12, so upgrades are rehearsed here first; the
  # backend tag is the commit the module's compose file mirrors
  backend_images = {
    backend = "ghcr.io/autonomys/auto-drive-backend:99e753be@sha256:78288688bf82fd87101eea25bed789410ef4ade33085978432dc91df0d7d80d2"
    hasura  = "hasura/graphql-engine:v2.40.0.cli-migrations-v3@sha256:68b16a019e4f6f3136fb09ef26a934c718e3ff74eab76d52244abccb8fd80b55"
  }

  # Production's backend settings, with Chronos and staging values in place of
  # mainnet's. The backend posts its metrics to VICTORIA_ENDPOINT as given, so
  # it names the write path.
  backend_settings = {
    NODE_ENV               = "production"
    OPTIONAL_AUTH          = "true"
    CORS_ALLOWED_ORIGINS   = ""
    FORBIDDEN_EXTENSIONS   = "exe,bin"
    STAFF_DOMAINS          = "@autonomys.xyz,@subspace.network"
    METRIC_ENVIRONMENT_TAG = "staging"
    VICTORIA_ACTIVE        = "true"
    VICTORIA_ENDPOINT      = "https://vmetrics.subspace.network/write"
    VICTORIA_USERNAME      = var.victoria_username
    EVM_CHAIN_ID           = "8700"
    # payments are off on staging; the address only has to be valid
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
  images   = local.backend_images

  run_migrations = true
  database_url   = local.database_url
  rabbitmq_url   = local.rabbitmq_url
  # the services deploy sets the passwords these URLs carry
  wait_for    = [module.services.deploy_id]
  database_id = local.services_database_id

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

locals {
  # 3030, where the backend looks for auth by default, is the backend worker's
  # port on the private host
  auth_port = 3040

  # Cloudflare's published IPv4 ranges, https://www.cloudflare.com/ips-v4, as
  # of 2026-11-14. A range added there is refused here until it is added too.
  cloudflare_ipv4 = [
    "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "141.101.64.0/18",
    "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20", "197.234.240.0/22", "198.41.128.0/17",
    "162.158.0.0/15", "104.16.0.0/13", "104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22",
  ]
}

module "private" {
  source = "../../../modules/auto-drive-backend-host"

  deployer = {
    ssh_user           = "ubuntu"
    ssh_agent_identity = var.ssh_agent_identity
    path_to_scripts    = "../../../scripts"
  }

  host = {
    ipv4     = var.private_host_ipv4
    hostname = "auto-drive-staging-private"
  }

  mesh = local.mesh["private"]

  # production's private host's COMPOSE_PROFILES: Hasura, the API, the worker
  # and the publish worker, the only on-chain publisher
  profiles = ["base", "frontend"]
  images   = local.backend_images

  # the public host runs the migrations
  database_url = local.database_url
  rabbitmq_url = local.rabbitmq_url
  # the services deploy sets the passwords these URLs carry, and the public
  # deploy's Hasura has applied the image's metadata and migrations before this
  # host's Hasura starts on the same database
  wait_for = [module.services.deploy_id, module.public.deploy_id]
  # a rebuilt services host starts with an empty database
  database_id = module.services.bootstrap_id

  endpoints = merge(local.backend_endpoints, {
    rpc = "wss://rpc-0.chronos.autonomys.xyz/ws"
  })

  # Production's private host's settings. ALL_SERVICES_ACTIVE turns on the task
  # manager, which the publish worker needs before it signs, and the
  # object-mapping listener. Its payment settings are left out with payments.
  settings = merge(local.backend_settings, {
    ALL_SERVICES_ACTIVE      = "true"
    API_DESCRIPTION_URL      = "https://chronos.auto-drive.autonomys.xyz/api/docs/raw"
    ATTRIBUTION_START        = "2026-11-11T00:00:00Z"
    CHAIN_CONFIRMATION_DEPTH = "12"
    DEBUG_LEVEL              = "DEBUG"
    RABBITMQ_PREFETCH        = "10"
  })

  secrets = {
    auth_service_api_key = var.auth_service_api_key
    files_gateway_token  = var.files_gateway_token
    extra = merge(
      { VICTORIA_PASSWORD = var.victoria_password },
      var.slack_webhook_url == "" ? {} : { SLACK_WEBHOOK_URL = var.slack_webhook_url },
    )
  }

  # the publish worker's signing seeds, kept out of the API's environment
  worker_secrets = {
    PRIVATE_KEYS_PATH = var.publish_private_keys
  }

  hasura_admin_secret = var.hasura_admin_secret
  hasura = {
    jwt_public_key = var.hasura_jwt_public_key
    enable_console = true
  }

  ingress = {
    site = "private"
    hostnames = {
      app = "chronos.auto-drive.autonomys.xyz"
    }
    # Staff only: onboarding, which is what lets an account upload, answers on
    # the auth port alone, reached through an SSH tunnel
    auth = {
      hostname          = "auth.staging.auto-drive.autonomys.xyz"
      port              = local.auth_port
      public_onboarding = false
    }
    # both names are proxied, so only Cloudflare has a reason to reach the origin
    allow_from = local.cloudflare_ipv4
    letsencrypt = {
      email = "admin@autonomys.xyz"
    }
  }
}

# Production runs auth as a Lambda; here it is a container on the private host,
# behind that host's nginx
module "auth" {
  source = "../../../modules/auto-drive-auth"

  deployer = {
    ssh_user           = "ubuntu"
    ssh_agent_identity = var.ssh_agent_identity
    path_to_scripts    = "../../../scripts"
  }

  host = {
    ipv4         = var.private_host_ipv4
    bootstrap_id = module.private.bootstrap_id
    staging_dir  = module.private.staging_dir
  }

  # A prerelease build of autonomys/auto-drive#966's head, the first to publish
  # an auth image. Move it to the merge commit's tag once that merges, as main's
  # builds are tagged with their commit.
  image = "ghcr.io/autonomys/auto-drive-auth:snapshot-6554f564@sha256:c689550a14ffa2815f81164283a388133548b1da3742628e30fee8d9a7771ffd"
  port  = local.auth_port

  database_url = local.auth_database_url
  # the services deploy creates the database and sets that password, and the
  # private backend's deploy installs the nginx that serves auth's name
  wait_for = [module.services.deploy_id, module.private.deploy_id]
  # a rebuilt services host starts with an empty database
  database_id = module.services.bootstrap_id

  jwt_private_key = var.auth_jwt_private_key
  jwt_public_key  = var.hasura_jwt_public_key
  api_secret      = var.auth_service_api_key

  # production's value
  settings = {
    cors_allowed_origins = "*"
  }
}
