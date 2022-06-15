variable "droplet-size" {
  description = "Droplet size slug"
  type = string
  default = "m6-2vcpu-16gb"
}

variable "droplet-region" {
  description = "Droplet region"
  type = string
  default = "ams3"
}

variable "node-snapshot-tag" {
  description = "Node snapshot tag"
  type = string
  default = "gemini-1b-2022-jun-10"
}

variable "farmer-snapshot-tag" {
  description = "Farmer snapshot tag"
  type = string
  default = "gemini-1b-2022-jun-10"
}
