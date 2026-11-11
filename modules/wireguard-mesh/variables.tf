variable "deployer" {
  description = "How Terraform reaches the host"
  type = object({
    ssh_user           = string
    ssh_agent_identity = string
    path_to_scripts    = string
  })
}

variable "host_ipv4" {
  description = "Public IPv4 of the host, which Terraform connects to over SSH. The host must already have been through host-bootstrap."
  type        = string
}

variable "mesh" {
  description = "The host's mesh address, the mesh subnet and UDP port, and every other member. A peer whose public_key is still empty is left out of the config until it is set."
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

  validation {
    condition = (
      can(regex("^[0-9]+(\\.[0-9]+){3}/[0-9]+$", var.mesh.subnet))
      && can(cidrhost(var.mesh.subnet, 0))
      && var.mesh.port >= 1 && var.mesh.port <= 65535 && floor(var.mesh.port) == var.mesh.port
    )
    error_message = "mesh.subnet must be an IPv4 CIDR and mesh.port a port from 1 to 65535."
  }

  validation {
    condition = alltrue([
      for a in concat([var.mesh.address], var.mesh.peers[*].address) :
      can(cidrhost("${a}/${split("/", var.mesh.subnet)[1]}", 0))
      && try(cidrhost("${a}/${split("/", var.mesh.subnet)[1]}", 0) == cidrhost(var.mesh.subnet, 0), false)
      && a != cidrhost(var.mesh.subnet, 0)
    ]) && length(distinct(concat([var.mesh.address], var.mesh.peers[*].address))) == length(var.mesh.peers) + 1
    error_message = "mesh.address and every peer address must be distinct host addresses inside mesh.subnet."
  }

  validation {
    condition = alltrue([
      for p in var.mesh.peers :
      can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", p.name))
      && can(regex("^[0-9]+(\\.[0-9]+){3}$", p.endpoint)) && can(cidrhost("${p.endpoint}/32", 0))
      && (p.public_key == "" || can(regex("^[A-Za-z0-9+/]{42}[AEIMQUYcgkosw480]=$", p.public_key)))
    ])
    error_message = "Each peer needs a lowercase DNS-label name, an IPv4 endpoint, and a public_key that is empty or a WireGuard public key."
  }
}
