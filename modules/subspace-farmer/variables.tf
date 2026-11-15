variable "deployer" {
  description = "How Terraform reaches the host"
  type = object({
    ssh_user           = string
    ssh_agent_identity = string
    path_to_scripts    = string
  })
}

variable "host" {
  description = "The host the farmer runs on, which another role has already bootstrapped: its public address, which the farmer also advertises to the DSN, that role's bootstrap_id, which sets the farmer up again whenever the host is, and the directory the bootstrap made for roles to upload files to"
  type = object({
    ipv4         = string
    bootstrap_id = string
    staging_dir  = string
  })

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+){3}$", var.host.ipv4)) && can(cidrhost("${var.host.ipv4}/32", 0))
    error_message = "host.ipv4 must be an IPv4 address."
  }
}

variable "chain" {
  description = "Chain the node syncs and the farmer farms, passed to the node as --chain"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.chain))
    error_message = "chain must be a chain name such as chronos or mainnet."
  }
}

variable "images" {
  description = "The node and farmer images, each pinned to a tag, a digest or both, from the same release"
  type = object({
    node   = string
    farmer = string
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

variable "sync" {
  description = "The node's --sync: snap, the node's default, or full. Snap sync needs reachable farmers on the chain to serve its segment headers; full sync imports every block from genesis. Either way the node keeps its default pruning."
  type        = string
  default     = "snap"

  validation {
    condition     = contains(["snap", "full"], var.sync)
    error_message = "sync must be snap or full."
  }
}

variable "farm_size" {
  description = "Space the farm allocates, in whole GiB or TiB. The farmer refuses less than about 1021 MiB, one sector and its overhead, so 1GiB is the smallest. Growing it extends the farm in place."
  type        = string

  validation {
    condition     = can(regex("^[1-9][0-9]*(GiB|TiB)$", var.farm_size))
    error_message = "farm_size must be a whole number of GiB or TiB, at least 1GiB, such as 1GiB or 10GiB."
  }
}

variable "reward_address" {
  description = "Address the farmer's rewards are paid to. It is public, so it may be kept in the repo."
  type        = string

  validation {
    condition     = can(regex("^[1-9A-HJ-NP-Za-km-z]{46,50}$", var.reward_address))
    error_message = "reward_address must be an SS58 address."
  }
}

variable "ports" {
  description = "Host ports for the node's P2P and DSN listeners and the farmer's DSN listener, each published as itself on every interface. The defaults are the node's and the farmer's own; a host that already runs a node on them needs others."
  type = object({
    node     = optional(number, 30333)
    node_dsn = optional(number, 30433)
    farmer   = optional(number, 30533)
  })
  default = {}

  validation {
    condition = alltrue([
      for port in values(var.ports) : port >= 1 && port <= 65535 && floor(port) == port
    ]) && length(distinct(values(var.ports))) == 3
    error_message = "ports must be three different port numbers from 1 to 65535."
  }
}

variable "wait_for" {
  description = "IDs of resources the farmer's deploy must follow, such as the deploy of the role that owns the host, so their image prunes and pulls don't overlap"
  type        = list(string)
  default     = []
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
  description = "Compose project name. Its volumes hold the node's chain data and the farm, so a deploy under another name starts both over."
  type        = string
  default     = "subspace-farmer"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.compose_project))
    error_message = "compose_project must be a Compose project name: lowercase letters, digits, dashes and underscores."
  }
}
