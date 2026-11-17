output "servers" {
  value       = keys(local.agents)
  description = "Servers running the host agent"
}
