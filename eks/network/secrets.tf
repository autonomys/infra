resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a secret for the SSH private key
resource "aws_secretsmanager_secret" "ssh_private_key" {
  name        = "github-eks-subspace-ssh-key"
  description = "GitHub Subspace SSH private key"
}

# Store the SSH private key in Secrets Manager
resource "aws_secretsmanager_secret_version" "ssh_private_key_version" {
  secret_id     = aws_secretsmanager_secret.ssh_private_key.id
  secret_string = tls_private_key.ssh_key.private_key_pem
}

# Create a secret for the SSH public key
resource "aws_secretsmanager_secret" "ssh_public_key" {
  name        = "github-eks-subspace-ssh-key-pub"
  description = "GitHub Subspace SSH public key"
}

# Store the SSH public key in Secrets Manager
resource "aws_secretsmanager_secret_version" "ssh_public_key_version" {
  secret_id     = aws_secretsmanager_secret.ssh_public_key.id
  secret_string = tls_private_key.ssh_key.public_key_openssh
}
