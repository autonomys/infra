variable "cluster_auth_base64" {
  type        = string
  description = "value of cluster_auth_base64"
  default     = ""
}

variable "bootstrap_extra_args" {
  type        = string
  description = "value of bootstrap_extra_args"
  default     = <<-EOT
    # extra args added
    [settings.kernel]
    lockdown = "integrity"
  EOT

}
