variable "droplet-size" {
  description = "Droplet size slug"
  type = string
  default = "m3-4vcpu-32gb"
}

variable "droplet-regions" {
  description = "Droplet regions"
  type = list(string)
  default = ["nyc1", "sfo3", "ams3", "fra1", "blr1", "sgp1"]
}

variable "node-snapshot-tag" {
  description = "Node snapshot tag"
  type = string
  default = "snapshot-2022-may-18"
}
