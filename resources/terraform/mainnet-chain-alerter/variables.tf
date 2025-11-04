variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_ssh_key_name" {
  description = "AWS deployer's SSH key"
  type        = string
}

variable "ssh_agent_identity" {
  description = "AWS SSH key's public key that is loaded into SSH-Agent"
  type        = string
}

variable "slack_secret" {
  description = "Slack's Oauth secret key"
  type        = string
  sensitive   = true
}

variable "uptimekuma_url" {
  description = "Uptimekuma health push monitor URL"
  type        = string
  sensitive   = true
}
