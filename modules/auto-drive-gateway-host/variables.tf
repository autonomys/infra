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
}

variable "object_mapping_start_block" {
  description = "Value for the node's --create-object-mappings"
  type        = string
}

variable "gateway_repo" {
  description = "Git URL of autonomys/auto-files-gateway, whose compose files define the services"
  type        = string
  default     = "https://github.com/autonomys/auto-files-gateway.git"
}

variable "gateway_repo_ref" {
  description = "Branch, tag or full commit SHA of gateway_repo to deploy from. Pin a full SHA so a deploy is reproducible."
  type        = string
}

variable "images" {
  description = "Image references for every service the compose files define. All are needed even for services not started: Compose rejects a model with an empty image."
  type = object({
    node                   = string
    gateway                = string
    file_retriever         = string
    object_mapping_indexer = string
  })
}

variable "services" {
  description = "Compose services to start. Services left out are not stopped if already running."
  type        = list(string)

  validation {
    condition = length(var.services) > 0 && alltrue([
      for s in var.services : contains(["subspace-node", "subspace-rpc-gateway", "file-retriever", "object-mapping-app"], s)
    ])
    error_message = "services must be a non-empty subset of subspace-node, subspace-rpc-gateway, file-retriever, object-mapping-app."
  }
}

variable "settings" {
  description = "Further non-secret settings the compose files read, such as RUST_LOG_NODE. Secrets never go here."
  type        = map(string)
  default     = {}
}

variable "compose_files" {
  description = "Compose files, relative to the gateway checkout, in the order the gateway repo's deploy playbook passes them"
  type        = list(string)
  default = [
    "docker/file-retriever/docker-compose.yml",
    "docker/file-retriever/docker-compose.prod.yml",
    "docker/object-mapping-indexer/docker-compose.yml",
    "docker/object-mapping-indexer/docker-compose.prod.yml",
  ]
}

# The gateway repo's deploy playbook never names the project, so Compose
# derives it from the first file's directory. Keeping that name keeps the
# volumes, the node's chain data among them, when a host deployed by that
# playbook adopts this role.
variable "compose_project" {
  description = "Compose project name"
  type        = string
  default     = "file-retriever"
}

variable "compose_profiles" {
  description = "Compose profiles to enable. subspace-node sits behind the node and production profiles, and services that depend on it fail validation without one."
  type        = list(string)
  default     = ["node", "production"]
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
  description = "The host's place in the private WireGuard mesh, passed to modules/wireguard-mesh, or null to leave it out. The mesh port is opened to each peer's endpoint."
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
