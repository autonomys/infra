variable "host_ipv4" {
  description = "Public IPv4 of the bare-metal host, which Terraform connects to over SSH. Sensitive so plans don't print the origin behind the proxied records."
  type        = string
  sensitive   = true
}

variable "ssh_agent_identity" {
  description = "Agent key Terraform offers first: its comment as `ssh-add -l` shows it, or the absolute path of its key file. The public key text itself matches nothing."
  type        = string
}

variable "letsencrypt_email" {
  description = "Contact address registered with the Let's Encrypt account"
  type        = string
}

variable "grafana_admin_user" {
  description = "Grafana admin username. Only takes effect when Grafana creates its database."
  type        = string
  sensitive   = true
}

variable "grafana_admin_password" {
  description = "Grafana admin password. The deploy resets the admin password to this on every run."
  type        = string
  sensitive   = true
}

variable "alertmanager_slack_webhook_url" {
  description = "Slack incoming webhook that Alertmanager posts to (#alerts)"
  type        = string
  sensitive   = true
}

variable "watchdog_push_url" {
  description = "Uptime Kuma push monitor URL that receives the always-firing Watchdog alert"
  type        = string
  sensitive   = true
}

variable "vmetrics_username" {
  description = "Basic auth username for metric writes through vmetrics.subspace.network"
  type        = string
  sensitive   = true
}

variable "vmetrics_password" {
  description = "Basic auth password for metric writes through vmetrics.subspace.network"
  type        = string
  sensitive   = true
}

variable "vmetrics_fleet_username" {
  description = "Basic auth username the host agents write metrics with; the host-agents project holds the same pair"
  type        = string
  sensitive   = true
}

variable "vmetrics_fleet_password" {
  description = "Basic auth password the host agents write metrics with"
  type        = string
  sensitive   = true
}
