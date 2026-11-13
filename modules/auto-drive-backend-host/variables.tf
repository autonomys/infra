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
  description = "The host's place in the private WireGuard mesh, passed to modules/wireguard-mesh, or null for a host that reaches its database and broker some other way"
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
  default = null
}

variable "profiles" {
  description = "Compose profiles to run, as production's COMPOSE_PROFILES: base,download on a public backend, base,frontend on a private one. base is Hasura."
  type        = list(string)

  validation {
    condition = length(var.profiles) > 0 && alltrue([
      for p in var.profiles : contains(["base", "frontend", "frontend-api", "frontend-worker", "download", "download-api", "download-worker"], p)
    ])
    error_message = "profiles must be a non-empty subset of base, frontend, frontend-api, frontend-worker, download, download-api, download-worker."
  }
}

variable "images" {
  description = "Image references, each pinned to a tag, a digest or both. The backend image also supplies Hasura's metadata and migrations and runs the backend's database migrations."
  type = object({
    backend = string
    hasura  = string
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

variable "publish_address" {
  description = "Address the containers' ports are published on. Ports Docker publishes bypass the host firewall, so the deploy refuses any address but loopback and the host's mesh address."
  type        = string
  default     = "127.0.0.1"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+){3}$", var.publish_address)) && can(cidrhost("${var.publish_address}/32", 0))
    error_message = "publish_address must be an IPv4 address."
  }
}

variable "ports" {
  description = "Host port of each service, under the compose file's variable names. Defaults are production's; production leaves the publish worker's unset, which Docker turns into a random port."
  type = object({
    hasura                  = optional(number, 6565)
    backend_api             = optional(number, 3000)
    backend_worker          = optional(number, 3030)
    backend_publish_worker  = optional(number, 3031)
    backend_download_api    = optional(number, 3000)
    backend_download_worker = optional(number, 3030)
  })
  default = {}

  validation {
    condition     = alltrue([for p in values(var.ports) : p >= 1 && p <= 65535 && floor(p) == p])
    error_message = "ports must be from 1 to 65535."
  }
}

variable "run_migrations" {
  description = "Run the backend's database migrations from the backend image before deploying. Exactly one host sharing a database should."
  type        = bool
  default     = false
}

variable "database_url" {
  description = "Postgres URL the backend services and Hasura connect with (DATABASE_URL)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^postgres(ql)?://[^\\s'#$]+$", var.database_url))
    error_message = "database_url must be a postgres:// URL without whitespace, quotes, '#' or '$'."
  }
}

variable "wait_for" {
  description = "IDs of resources this host's migrations and deploy must follow, such as the services host's deploy, which sets the passwords in database_url and rabbitmq_url"
  type        = list(string)
  default     = []
}

variable "database_id" {
  description = "Changes whenever the database may have been recreated empty, such as the services host's bootstrap_id. A change re-runs the migrations and recreates Hasura and the backend services, so the schema and Hasura's metadata are set up again."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]*$", var.database_id))
    error_message = "database_id must be letters, digits, '.', '_' or '-'."
  }
}

variable "migration_database_url" {
  description = "Postgres URL the migrations run with; null uses database_url. It is staged on the host only for the migration run, never written to the services' .env."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.migration_database_url == null || can(regex("^postgres(ql)?://[^\\s'#$]+$", var.migration_database_url))
    error_message = "migration_database_url must be null or a postgres:// URL without whitespace, quotes, '#' or '$'."
  }
}

variable "rabbitmq_url" {
  description = "AMQP URL the backend services connect with (RABBITMQ_URL)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^amqps?://[^\\s'#$]+$", var.rabbitmq_url))
    error_message = "rabbitmq_url must be an amqp:// or amqps:// URL without whitespace, quotes, '#' or '$'."
  }
}

variable "endpoints" {
  description = "Services the backend calls: the consensus chain RPC, the object mapping indexer, the files gateway, the auth service and the Auto EVM RPC"
  type = object({
    rpc                     = string
    object_mapping_archiver = string
    files_gateway           = string
    auth_service            = string
    evm_chain               = string
  })

  validation {
    condition = alltrue([
      for url in values(var.endpoints) : can(regex("^(https?|wss?)://[^\\s'#$]+$", url))
    ])
    error_message = "Each endpoint must be an http(s) or ws(s) URL without whitespace, quotes, '#' or '$'."
  }
}

variable "settings" {
  description = "Further non-secret backend settings for the .env, such as NODE_ENV or METRIC_ENVIRONMENT_TAG. Secrets go in secrets."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.settings :
      can(regex("^[A-Z][A-Z0-9_]*$", k)) && !can(regex("['\\n\\r$]", v))
    ])
    error_message = "settings keys must be upper-case env names, and values must not contain quotes, newlines or '$'."
  }
}

variable "secrets" {
  description = "Secrets for the .env: the auth service's API key, the files gateway's token, and any further ones by env name"
  type = object({
    auth_service_api_key = string
    files_gateway_token  = string
    extra                = optional(map(string), {})
  })
  sensitive = true

  validation {
    condition = alltrue([
      for v in concat([var.secrets.auth_service_api_key, var.secrets.files_gateway_token], values(var.secrets.extra)) :
      length(v) > 0 && !can(regex("['\\n\\r$]", v))
      ]) && alltrue([
      for k in keys(var.secrets.extra) : can(regex("^[A-Z][A-Z0-9_]*$", k))
    ])
    error_message = "secrets must be non-empty and free of quotes, newlines and '$', and extra keys upper-case env names."
  }
}

variable "hasura_admin_secret" {
  description = "Hasura's admin secret"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.hasura_admin_secret) >= 32 && !can(regex("['\\n\\r$]", var.hasura_admin_secret))
    error_message = "hasura_admin_secret must be at least 32 characters without quotes, newlines or '$'."
  }
}

variable "hasura" {
  description = "The public key Hasura verifies auth's RS256 tokens with, whether it applies the SQL migrations shipped in the backend image, and the console and CORS settings production sets in its .env"
  type = object({
    jwt_public_key       = string
    apply_sql_migrations = optional(bool, true)
    enable_console       = optional(bool, false)
    cors_domain          = optional(string, "*")
  })

  validation {
    condition = (
      can(regex("^-----BEGIN PUBLIC KEY-----\\n[A-Za-z0-9+/=\\n]+-----END PUBLIC KEY-----\\n?$", var.hasura.jwt_public_key))
      && can(regex("^[^'\"\\s$]+$", var.hasura.cors_domain))
    )
    error_message = "hasura.jwt_public_key must be a PEM public key, and cors_domain free of quotes, whitespace and '$'."
  }
}

variable "ingress" {
  description = "Host nginx in front of the services: the hostnames it serves, the Let's Encrypt account its certificates are issued under, where / redirects (null answers 404), and Cloudflare ranges whose CF-Connecting-IP header nginx trusts (empty trusts none, as production does)"
  type = object({
    site = string
    hostnames = object({
      app     = string
      s3      = optional(string)
      gateway = optional(string)
    })
    letsencrypt = object({
      email   = string
      staging = optional(bool, false)
    })
    root_redirect_url = optional(string)
    real_ip_from      = optional(list(string), [])
  })

  validation {
    condition     = var.ingress.site == "public"
    error_message = "ingress.site must be public; the private host's site is not written yet."
  }

  validation {
    condition = alltrue([
      for h in compact([var.ingress.hostnames.app, var.ingress.hostnames.s3, var.ingress.hostnames.gateway]) :
      can(regex("^([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z]{2,}$", h))
    ])
    error_message = "ingress.hostnames must be lowercase DNS names."
  }

  validation {
    condition     = can(regex("^[A-Za-z0-9._%+-]+@([A-Za-z0-9-]+\\.)+[a-z]{2,}$", var.ingress.letsencrypt.email))
    error_message = "ingress.letsencrypt.email must be an email address."
  }

  validation {
    condition = (
      (var.ingress.root_redirect_url == null || can(regex("^https://([a-z0-9-]+\\.)+[a-z]{2,}(/[A-Za-z0-9._~/-]*)?$", var.ingress.root_redirect_url)))
      && alltrue([for c in var.ingress.real_ip_from : can(cidrhost(c, 0))])
    )
    error_message = "ingress.root_redirect_url must be null or an https URL, and real_ip_from CIDRs."
  }
}

variable "cap_local_logs" {
  description = "Cap the loki driver's local copy of the containers' logs at 10m x 3, as on the rest of the fleet. Turning it on or off recreates the services."
  type        = bool
  default     = true
}

variable "loki_url" {
  description = "Loki push URL the containers' log driver sends to"
  type        = string
  default     = "https://logging.subspace.network/loki/api/v1/push"

  validation {
    condition     = can(regex("^https?://[^\\s'\"$]+$", var.loki_url))
    error_message = "loki_url must be an http or https URL."
  }
}

# Production's project name, so container and volume names match its hosts'
variable "compose_project" {
  description = "Compose project name"
  type        = string
  default     = "auto-drive"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.compose_project))
    error_message = "compose_project must be a Compose project name: lowercase letters, digits, dashes and underscores."
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
