variable "gateway_host_ipv4" {
  description = "Public IPv4 of the files gateway host, which Terraform connects to over SSH"
  type        = string
}

variable "ssh_agent_identity" {
  description = "SSH key's public key that is loaded into SSH-Agent"
  type        = string
}
