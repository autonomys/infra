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
    ipv4            = string
    hostname        = string
    loki_domain     = string
    grafana_domain  = string
    vmetrics_domain = string
    # how many disks smartctl should see; fewer fires DiskMissing
    disks = number
  })
}

variable "letsencrypt_email" {
  description = "Contact address registered with the Let's Encrypt account"
  type        = string
}

variable "grafana_admin" {
  description = "Grafana admin login. The deploy resets the admin password to this on every run."
  type = object({
    user     = string
    password = string
  })
  sensitive = true
}

variable "alerting" {
  description = "Alertmanager's Slack incoming webhook for #alerts, and the Uptime Kuma push URL that receives the Watchdog heartbeat"
  type = object({
    slack_webhook_url = string
    watchdog_push_url = string
  })
  sensitive = true
}

variable "vmetrics_writer" {
  description = "Basic auth credential for metric writes through vmetrics.subspace.network"
  type = object({
    username = string
    password = string
  })
  sensitive = true
}

variable "vmetrics_fleet" {
  description = "Basic auth credential the host agents write metrics with, through vmetrics.subspace.network"
  type = object({
    username = string
    password = string
  })
  sensitive = true
}

variable "host_key" {
  description = "The box's ECDSA host key (\"ecdsa-sha2-nistp256 AAAA...\"), checked before anything is sent. Terraform's SSH client asks for an ECDSA key first, so an ed25519 key here fails as a mismatch."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ecdsa-sha2-nistp(256|384|521) [A-Za-z0-9+/]+=*$", var.host_key))
    error_message = "host_key must be the box's ECDSA public key, \"ecdsa-sha2-nistp256 AAAA...\", without a host name or comment."
  }
}
