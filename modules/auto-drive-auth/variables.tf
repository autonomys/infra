variable "deployer" {
  description = "How Terraform reaches the host"
  type = object({
    ssh_user           = string
    ssh_agent_identity = string
    path_to_scripts    = string
  })
}

variable "host" {
  description = "The host auth runs on, which another role has already bootstrapped: its address, that role's bootstrap_id, which sets auth up again whenever the host is, and the directory the bootstrap made for roles to upload files to"
  type = object({
    ipv4         = string
    bootstrap_id = string
    staging_dir  = string
  })
}

variable "image" {
  description = "The auth image, pinned to a tag, a digest or both. It also runs auth's database migrations."
  type        = string

  # name (a registry may carry a port), then a tag, a digest or both
  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9._-]*(:[0-9]+)?(/[a-z0-9][a-z0-9._-]*)*(:[A-Za-z0-9_][A-Za-z0-9._-]*)?(@sha256:[0-9a-f]{64})?$", var.image))
      && can(regex("(:[A-Za-z0-9_][A-Za-z0-9._-]*|@sha256:[0-9a-f]{64})$", var.image))
      && !can(regex(":latest(@|$)", var.image))
    )
    error_message = "image must be pinned to a tag other than latest, a digest, or a tag and a digest."
  }
}

variable "publish_address" {
  description = "Address auth's port is published on. Ports Docker publishes bypass the host firewall, so the deploy refuses any address but loopback and private_addresses."
  type        = string
  default     = "127.0.0.1"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+){3}$", var.publish_address)) && can(cidrhost("${var.publish_address}/32", 0))
    error_message = "publish_address must be an IPv4 address."
  }
}

variable "private_addresses" {
  description = "Addresses besides loopback that the deploy accepts as publish_address, such as the host's mesh address"
  type        = list(string)
  default     = []
}

variable "port" {
  description = "Host port auth is published on. The default is the port the backend looks for auth on; a host whose backend worker already has it needs another."
  type        = number
  default     = 3030

  validation {
    condition     = var.port >= 1 && var.port <= 65535 && floor(var.port) == var.port
    error_message = "port must be from 1 to 65535."
  }
}

variable "database_url" {
  description = "Postgres URL of auth's own database, which its migrations run against too (DATABASE_URL)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^postgres(ql)?://[^\\s'#$]+$", var.database_url))
    error_message = "database_url must be a postgres:// URL without whitespace, quotes, '#' or '$'."
  }
}

variable "wait_for" {
  description = "IDs of resources auth's deploy must follow, such as the deploy that creates its database and sets the password in database_url"
  type        = list(string)
  default     = []
}

variable "database_id" {
  description = "Changes whenever the database may have been recreated empty, such as when the host it lives on is rebuilt, and at no other time. A change recreates auth, which keeps the one connection it opens."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]*$", var.database_id))
    error_message = "database_id must be letters, digits, '.', '_' or '-'."
  }
}

variable "jwt_private_key" {
  description = "PEM private key auth signs its tokens with (JWT_SECRET, which auth reads base64-encoded)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^-----BEGIN (RSA )?PRIVATE KEY-----\\n[A-Za-z0-9+/=\\n]+-----END (RSA )?PRIVATE KEY-----\\n?$", var.jwt_private_key))
    error_message = "jwt_private_key must be a PEM private key."
  }
}

variable "jwt_public_key" {
  description = "PEM public key that whatever verifies auth's tokens holds, such as Hasura. The deploy refuses a jwt_private_key that is not its other half."
  type        = string

  validation {
    condition     = can(regex("^-----BEGIN PUBLIC KEY-----\\n[A-Za-z0-9+/=\\n]+-----END PUBLIC KEY-----\\n?$", var.jwt_public_key))
    error_message = "jwt_public_key must be a PEM public key."
  }
}

variable "api_secret" {
  description = "Secret the backend presents to auth as its service credential (API_SECRET; the backend's AUTH_SERVICE_API_KEY)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.api_secret) >= 32 && !can(regex("['\\n\\r$]", var.api_secret))
    error_message = "api_secret must be at least 32 characters without quotes, newlines or '$'."
  }
}

variable "settings" {
  description = "Auth's settings that are not secret: the signing algorithm, the origins CORS allows (empty allows none), the frontend origins wallet sign-in messages may be issued for, the log level, and a Unix time before which issued tokens are refused (0 refuses none)"
  type = object({
    jwt_algorithm               = optional(string, "RS256")
    cors_allowed_origins        = optional(string, "")
    web3_allowed_origins        = optional(string, "https://explorer.ai3.storage")
    log_level                   = optional(string, "info")
    revoke_tokens_issued_before = optional(number, 0)
  })
  default = {}

  validation {
    condition     = contains(["RS256", "RS384", "RS512"], var.settings.jwt_algorithm)
    error_message = "settings.jwt_algorithm must be RS256, RS384 or RS512, the algorithms a PEM key pair signs with."
  }

  validation {
    condition = alltrue([
      for v in [var.settings.cors_allowed_origins, var.settings.web3_allowed_origins, var.settings.log_level] : !can(regex("['\\s$]", v))
    ]) && var.settings.revoke_tokens_issued_before >= 0 && floor(var.settings.revoke_tokens_issued_before) == var.settings.revoke_tokens_issued_before
    error_message = "settings values must be free of quotes, whitespace and '$', and revoke_tokens_issued_before a whole number of seconds."
  }
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

variable "compose_project" {
  description = "Compose project name"
  type        = string
  default     = "auto-drive-auth"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.compose_project))
    error_message = "compose_project must be a Compose project name: lowercase letters, digits, dashes and underscores."
  }
}
