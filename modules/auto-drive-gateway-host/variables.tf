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

variable "network_id" {
  description = "Chain the node syncs, passed to the node as --chain"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.network_id))
    error_message = "network_id must be a chain name such as chronos or mainnet."
  }
}

variable "create_object_mappings" {
  description = "The node's --create-object-mappings. yes creates mappings as blocks are archived and carries on across restarts. A block number creates them from that block, and every node start then re-archives the chain from it, which takes hours on a long chain."
  type        = string

  validation {
    condition     = can(regex("^(yes|[1-9][0-9]*)$", var.create_object_mappings))
    error_message = "create_object_mappings must be yes or a block number above 0."
  }
}

variable "images" {
  description = "Image reference for each service, pinned to a tag, a digest or both"
  type = object({
    node = string
  })

  # name (a registry may carry a port), then a tag, a digest or both
  validation {
    condition = alltrue([
      for image in values(var.images) :
      can(regex("^[a-z0-9][a-z0-9._-]*(:[0-9]+)?(/[a-z0-9][a-z0-9._-]*)*(:[A-Za-z0-9_][A-Za-z0-9._-]*)?(@sha256:[0-9a-f]{64})?$", image))
      && can(regex("(:[A-Za-z0-9_][A-Za-z0-9._-]*|@sha256:[0-9a-f]{64})$", image))
      && !endswith(image, ":latest")
    ])
    error_message = "Each image must be pinned to a tag other than latest, a digest, or a tag and a digest."
  }
}

variable "node_rust_log" {
  description = "The node's RUST_LOG"
  type        = string
  default     = "info"

  validation {
    condition     = can(regex("^[A-Za-z0-9_=,:./-]+$", var.node_rust_log))
    error_message = "node_rust_log must be a RUST_LOG filter such as info or info,sub-libp2p=debug."
  }
}

variable "cap_local_logs" {
  description = "Cap the loki driver's local copy of the containers' logs at 10m x 3, as on the rest of the fleet. Turning it on or off recreates the node."
  type        = bool
  default     = true
}

variable "loki_url" {
  description = "Loki push URL the containers' log driver sends to"
  type        = string
  default     = "https://logging.subspace.network/loki/api/v1/push"

  validation {
    condition     = can(regex("^https?://[^\"'\\s]+$", var.loki_url))
    error_message = "loki_url must be an http or https URL without quotes or spaces."
  }
}

# The gateway repo's deploy playbook never names the project, so Compose
# derives it from the first file's directory. Keeping that name keeps the
# volumes, the node's chain data among them, when a host deployed by that
# playbook adopts this role.
variable "compose_project" {
  description = "Compose project name"
  type        = string
  default     = "file-retriever"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.compose_project))
    error_message = "compose_project must be a Compose project name: lowercase letters, digits, dashes and underscores."
  }
}

variable "public_tcp_ports" {
  description = "Ports the gateway may publish beyond loopback. The deploy refuses any other port published beyond loopback and the host's mesh address."
  type        = list(number)
  default     = [30333, 30433]
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

variable "mesh" {
  description = "The host's place in the private WireGuard mesh, passed to modules/wireguard-mesh, or null to leave it out."
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
