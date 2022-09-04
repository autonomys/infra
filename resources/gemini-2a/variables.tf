variable "droplet-size" {
  description = "Droplet size"
  type = string
  default = "m6-2vcpu-16gb"
}

variable "rpc-node-regions" {
  description = "RPC node regions"
  type = list(string)
  default = ["nyc1", "sfo3", "blr1", "sgp1"]
}

variable "rpc-nodes-per-region" {
  description = "RPC nodes per region"
  type = number
  default = 3
}

variable "bootstrap-node-regions" {
  description = "Bootstrap node regions"
  type = list(string)
  default = ["nyc1", "sfo3", "blr1", "sgp1", "nyc1", "sgp1"]
}

variable "bootstrap-nodes-per-region" {
  description = "Bootstrap nodes per region"
  type = number
  default = 1
}

variable "node-snapshot-tag" {
  description = "Node snapshot tag"
  type = string
  default = "gemini-2a-pre-release"
}

variable "hetzner_bootstrap_node_ips" {
  description = "Hetzner bootstrap ip v4"
  type = list(string)
}

variable "hetzner_full_node_ips" {
  description = "Hetzner full node ip v4"
  type = list(string)
}

variable "hetzner_rpc_node_ips" {
  description = "Hetzner rpc node ip v4"
  type = list(string)
}
