output "eks-endpoint" {
  value = aws_eks_cluster.vault.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.vault.certificate_authority[0].data
}

output "eks_issuer_url" {
  value = aws_iam_openid_connect_provider.openid.url
}

output "vault_secret_name" {
  value = "vault-secret-${random_string.vault-secret-suffix.result}"
}

output "nat1_ip" {
  value = aws_eip.nat["public-vault-1"].public_ip
}

output "nat2_ip" {
  value = aws_eip.nat["public-vault-2"].public_ip
}

output "nat3_ip" {
  value = aws_eip.nat["public-vault-3"].public_ip
}
