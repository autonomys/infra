variable "servers" {
  description = "Each server in local.agents, by name: its IPv4 address and ECDSA host key (\"ecdsa-sha2-nistp256 AAAA...\")"
  type = map(object({
    ipv4     = string
    host_key = string
  }))
  sensitive = true
}

variable "ssh_agent_identity" {
  description = "Agent key Terraform offers first: its comment as `ssh-add -l` shows it, or the absolute path of its key file. The public key text itself matches nothing."
  type        = string
}

variable "vmetrics_fleet_username" {
  description = "Basic auth username the agents write metrics with; vmauth on the monitoring host holds the same pair"
  type        = string
  sensitive   = true
}

variable "vmetrics_fleet_password" {
  description = "Basic auth password the agents write metrics with"
  type        = string
  sensitive   = true
}
