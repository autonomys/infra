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

variable "account_private_key" {
  description = "0x-prefixed 32-byte hex private key"
  type        = string
  sensitive   = true
}
