variable "deployer" {
  description = "How Terraform reaches the host"
  type = object({
    ssh_user           = string
    ssh_agent_identity = string
    path_to_scripts    = string
  })
}

variable "host" {
  description = "An existing Ubuntu host, reachable over SSH as deployer.ssh_user with passwordless sudo"
  type = object({
    ipv4     = string
    hostname = string
  })
}

variable "mesh" {
  description = "The host's place in the private WireGuard mesh, passed to modules/wireguard-mesh. Postgres and RabbitMQ are published on its address for the other members."
  type = object({
    address = string
    subnet  = string
    port    = number
    peers = list(object({
      name       = string
      endpoint   = string
      address    = string
      public_key = string
    }))
  })
}

variable "images" {
  description = "Image references for Postgres and RabbitMQ, each pinned to a tag, a digest or both. Changing a major version needs a data migration first."
  type = object({
    postgres = string
    rabbitmq = string
  })

  # name (a registry may carry a port), then a tag, a digest or both
  validation {
    condition = alltrue([
      for image in values(var.images) :
      can(regex("^[a-z0-9][a-z0-9._-]*(:[0-9]+)?(/[a-z0-9][a-z0-9._-]*)*(:[A-Za-z0-9_][A-Za-z0-9._-]*)?(@sha256:[0-9a-f]{64})?$", image))
      && can(regex("(:[A-Za-z0-9_][A-Za-z0-9._-]*|@sha256:[0-9a-f]{64})$", image))
      && !can(regex(":latest(@|$)", image))
    ])
    error_message = "Each image must be pinned to a tag other than latest, a digest, or a tag and a digest."
  }
}

variable "postgres" {
  description = "Postgres sizing and the databases to create besides postgres. settings sets the server parameters compose/docker-compose.yml passes as -c name=value, each of them and no others."
  type = object({
    databases        = list(string)
    memory_limit_gib = number
    shm_size_gib     = number
    settings         = map(string)
  })

  validation {
    condition = alltrue([
      for db in var.postgres.databases : can(regex("^[a-z][a-z0-9_]{0,62}$", db)) && db != "postgres"
    ])
    error_message = "postgres.databases must be lowercase identifiers other than postgres."
  }

  validation {
    condition = alltrue([
      for k, v in var.postgres.settings : can(regex("^[a-z_]+$", k)) && can(regex("^[A-Za-z0-9._]+$", v))
    ])
    error_message = "postgres.settings names must be lowercase Postgres parameter names and values plain words or numbers."
  }

  validation {
    condition = toset(keys(var.postgres.settings)) == toset([
      "effective_cache_size", "effective_io_concurrency", "maintenance_work_mem", "max_connections",
      "max_wal_size", "random_page_cost", "shared_buffers", "work_mem",
    ])
    error_message = "postgres.settings must set exactly the parameters compose/docker-compose.yml passes as -c; add a new one there first."
  }
}

variable "postgres_password" {
  description = "Password of the postgres account the applications use"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9]{32,}$", var.postgres_password))
    error_message = "postgres_password must be at least 32 letters and digits, so it needs no escaping in a connection URL."
  }
}

variable "rabbitmq" {
  description = "RabbitMQ sizing. The broker is told its memory limit, since it does not read the container's."
  type = object({
    memory_limit_gib = number
  })
}

variable "rabbitmq_username" {
  description = "RabbitMQ account the applications use. It is created when the broker first starts; changing it later needs a fresh broker volume."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,64}$", var.rabbitmq_username))
    error_message = "rabbitmq_username must be letters, digits, '_' or '-'."
  }
}

variable "rabbitmq_password" {
  description = "Password of rabbitmq_username"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9]{32,}$", var.rabbitmq_password))
    error_message = "rabbitmq_password must be at least 32 letters and digits, so it needs no escaping in a connection URL."
  }
}

variable "loki_url" {
  description = "Loki push endpoint the containers' logs ship to"
  type        = string
  default     = "https://logging.subspace.network/loki/api/v1/push"

  validation {
    condition     = can(regex("^https?://[^\\s'\"$]+$", var.loki_url))
    error_message = "loki_url must be an http or https URL."
  }
}

variable "peer_rules" {
  description = "Ports open only to named peer addresses; passed to host-bootstrap"
  type = list(object({
    port     = number
    protocol = string
    from     = string
  }))
  default = []
}
