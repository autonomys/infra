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

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.host.hostname))
    error_message = "host.hostname must be a single lowercase DNS label."
  }
}

variable "public_tcp_ports" {
  description = "TCP ports the host's role serves to the internet, besides SSH"
  type        = list(number)
  default     = []
}

variable "peer_rules" {
  description = "Ports open only to named peer addresses, such as a private network between hosts. Peer addresses belong in tfvars, not the repo."
  type = list(object({
    port     = number
    protocol = string
    from     = string
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.peer_rules : contains(["tcp", "udp"], r.protocol) && can(cidrhost(strcontains(r.from, "/") ? r.from : "${r.from}/32", 0))
    ])
    error_message = "Each peer rule needs protocol tcp or udp and from set to an IPv4 address or CIDR."
  }
}
