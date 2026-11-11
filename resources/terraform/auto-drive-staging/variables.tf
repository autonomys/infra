variable "gateway_host_ipv4" {
  description = "Public IPv4 of the files gateway host, which Terraform connects to over SSH"
  type        = string
}

variable "mesh_public_keys" {
  description = "WireGuard public key of each mesh host, keyed as in local.mesh_hosts. A host's key exists once its first apply has run; until it is added here, its peers leave it out."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k in values(var.mesh_public_keys) : can(regex("^[A-Za-z0-9+/]{42}[AEIMQUYcgkosw480]=$", k))])
    error_message = "Each mesh_public_keys value must be a WireGuard public key."
  }
}

variable "ssh_agent_identity" {
  description = "SSH key's public key that is loaded into SSH-Agent"
  type        = string
}
