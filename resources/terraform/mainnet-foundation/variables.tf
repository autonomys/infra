variable "cloudflare_api_token" {
  description = "Cloudflare api token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare zone specific accountID"
  type        = string
  sensitive   = true
}

variable "ssh_agent_identity" {
  description = "AWS SSH key's public key that is loaded into SSH-Agent"
  type        = string
}

variable "new_relic_api_key" {
  description = "New relic API Key"
  type        = string
  sensitive   = true
}

variable "consensus_rpc_ipv4" {
  description = "Consensus RPC IPv4"
  type        = map(string)
}
