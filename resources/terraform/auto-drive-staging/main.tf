# The private mesh between the staging hosts. Mesh addresses are private and
# fixed per role; endpoints and public keys come from tfvars.
locals {
  mesh_port   = 51820
  mesh_subnet = "10.77.0.0/24"
  mesh_hosts = {
    services      = { endpoint = var.services_host_ipv4, address = "10.77.0.10" }
    files-gateway = { endpoint = var.gateway_host_ipv4, address = "10.77.0.20" }
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
