variable "deployer" {
  description = "Deployer specific details"
  type = object({
    ssh_user           = string
    ssh_agent_identity = string
    path_to_scripts    = string
  })
}

variable "instance" {
  description = "Monitoring host details"
  type = object({
    ipv4        = string
    hostname    = string
    loki_domain = string
  })
}

variable "letsencrypt_email" {
  description = "Contact address registered with the Let's Encrypt account"
  type        = string
}
