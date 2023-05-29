# Output Vault instance details
output "vault_instance_ip" {
  value = aws_instance.vault.public_ip
}
