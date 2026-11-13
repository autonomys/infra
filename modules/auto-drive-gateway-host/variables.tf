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

variable "object_mapping_start_block" {
  description = "Value for the node's --create-object-mappings. Every node start re-archives from this block."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.object_mapping_start_block))
    error_message = "object_mapping_start_block must be a block number."
  }
}

variable "images" {
  description = "Image reference for each service, pinned to a tag or digest"
  type = object({
    node = string
  })

  validation {
    condition = alltrue([
      for image in values(var.images) :
      can(regex("^[a-z0-9./_-]+(:[A-Za-z0-9._-]+|@sha256:[0-9a-f]{64})$", image)) && !endswith(image, ":latest")
    ])
    error_message = "Each image must be pinned to a tag other than latest, or to a digest."
  }
}

variable "node" {
  description = "Node settings that differ between environments: its name on the network and its RUST_LOG"
  type = object({
    name     = optional(string, "object-mapping-node")
    rust_log = optional(string, "info")
  })
  default = {}

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.node.name)) && can(regex("^[A-Za-z0-9_=,:./-]+$", var.node.rust_log))
    error_message = "node.name may hold letters, digits, dots, dashes and underscores; node.rust_log must be a RUST_LOG filter such as info or info,sub-libp2p=debug."
  }
}

variable "loki_url" {
  description = "Loki push URL the containers' log driver sends to"
  type        = string
  default     = "https://logging.subspace.network/loki/api/v1/push"

  validation {
    condition     = can(regex("^https?://[^\"\\s]+$", var.loki_url))
    error_message = "loki_url must be an http or https URL."
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

variable "allow_node_restart" {
  description = "Let a deploy recreate a running node, for an image upgrade or a changed setting. The deploy refuses otherwise, since every node start re-archives from object_mapping_start_block. Set it for that apply only."
  type        = bool
  default     = false
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
