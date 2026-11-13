variable "gateway_host_ipv4" {
  description = "Public IPv4 of the files gateway host, which Terraform connects to over SSH"
  type        = string
}

variable "services_host_ipv4" {
  description = "Public IPv4 of the services host, which Terraform connects to over SSH"
  type        = string
}

variable "public_host_ipv4" {
  description = "Public IPv4 of the public backend host, which Terraform connects to over SSH"
  type        = string
}

variable "postgres_password" {
  description = "Password of the services host's postgres account, from services.auto.tfvars"
  type        = string
  sensitive   = true
}

variable "rabbitmq_username" {
  description = "The services host's RabbitMQ account, from services.auto.tfvars"
  type        = string
}

variable "rabbitmq_password" {
  description = "Password of rabbitmq_username, from services.auto.tfvars"
  type        = string
  sensitive   = true
}

variable "hasura_admin_secret" {
  description = "Hasura's admin secret on the backend hosts, from backend.auto.tfvars"
  type        = string
  sensitive   = true
}

variable "hasura_jwt_public_key" {
  description = "PEM public key of the RS256 pair auth signs its tokens with, which Hasura verifies them against, from backend.auto.tfvars"
  type        = string
}

variable "auth_service_api_key" {
  description = "Key the backend presents to the auth service, which auth knows as API_SECRET, from backend.auto.tfvars"
  type        = string
  sensitive   = true
}

variable "files_gateway_token" {
  description = "The files gateway's file retriever API secret, from gateway.auto.tfvars. The backends present it as FILES_GATEWAY_TOKEN."
  type        = string
  sensitive   = true
}

variable "victoria_username" {
  description = "Account the backend pushes its metrics to VictoriaMetrics with, from backend.auto.tfvars"
  type        = string
}

variable "victoria_password" {
  description = "Password of victoria_username, from backend.auto.tfvars"
  type        = string
  sensitive   = true
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook for tasks that exhaust their retries, from backend.auto.tfvars. Empty leaves alerting off and the error queues unconsumed."
  type        = string
  default     = ""
  sensitive   = true
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
