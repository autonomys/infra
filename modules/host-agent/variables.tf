variable "deployer" {
  description = "How Terraform reaches the host"
  type = object({
    ssh_user           = string
    ssh_agent_identity = string
    path_to_scripts    = string
  })
}

variable "host" {
  description = "An existing Ubuntu server with Docker, the Compose plugin and the loki log driver, reachable over SSH as deployer.ssh_user (root, or a user with passwordless sudo)"
  type = object({
    # the host label on every series
    name = string
    # the server's ECDSA host key ("ecdsa-sha2-nistp256 AAAA..."), checked before
    # anything is sent. Terraform's SSH client asks for an ECDSA key before an
    # ed25519 one, so a server that has both presents its ECDSA key, and an ed25519
    # key here fails as a mismatch.
    host_key = string
    # how many disks smartctl should see; fewer fires DiskMissing
    disks = number
    # other metrics endpoints on the server to scrape, job name => port on 127.0.0.1
    scrape_ports = map(number)
  })

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9.-]{0,61}[a-z0-9])?$", var.host.name))
    error_message = "host.name must be lowercase letters, digits, dots and hyphens."
  }

  validation {
    condition = alltrue([
      for job in keys(var.host.scrape_ports) :
      can(regex("^[a-z0-9][a-z0-9_-]*$", job)) && !contains(["node", "smartctl", "vmagent"], job)
    ])
    error_message = "host.scrape_ports names must be lowercase letters, digits, hyphens and underscores, and not node, smartctl or vmagent, which the agent already scrapes."
  }

  validation {
    condition     = can(regex("^ecdsa-sha2-nistp(256|384|521) [A-Za-z0-9+/]+=*$", var.host.host_key))
    error_message = "host.host_key must be the server's ECDSA public key, \"ecdsa-sha2-nistp256 AAAA...\", without a host name or comment."
  }
}

variable "ipv4" {
  description = "The server's address"
  type        = string
  sensitive   = true
}

variable "images" {
  description = "Image references for the agent's containers, each pinned to a tag, a digest or both"
  type = object({
    vmagent           = string
    node_exporter     = string
    smartctl_exporter = string
    python            = string
  })

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

variable "loki_url" {
  description = "Loki push URL the loki log driver sends the agent's own logs to"
  type        = string
}

variable "vmetrics_url" {
  description = "Prometheus remote write URL vmagent writes to"
  type        = string
}

variable "vmetrics_credential" {
  description = "Basic auth credential vmagent writes with"
  type = object({
    username = string
    password = string
  })
  sensitive = true
}
