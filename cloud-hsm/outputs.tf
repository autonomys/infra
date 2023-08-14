output "vpc_id" {
  description = "The id of the VPC that the CloudHSM cluster resides in."
  value       = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.*.vpc_id
}

output "cluster_id" {
  description = "The id of the CloudHSM cluster."
  value       = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.*.id
}

output "cluster_state" {
  description = "The state of the CloudHSM cluster."
  value       = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.*.cluster_state
}

output "hsm_id" {
  description = "The ID of the HSM module."
  value       = aws_cloudhsm_v2_hsm.cloudhsm_v2_hsm.*.hsm_id
}

output "hsm_state" {
  description = "The state of the HSM module."
  value       = aws_cloudhsm_v2_hsm.cloudhsm_v2_hsm.*.hsm_state
}

output "hsm_eni_id" {
  description = "The id of the ENI interface allocated for HSM module."
  value       = aws_cloudhsm_v2_hsm.cloudhsm_v2_hsm.*.hsm_eni_id
}

output "security_group_id" {
  description = "The ID of the security group associated with the CloudHSM cluster."
  value       = aws_security_group.cloudhsm_sg.id
}

output "cluster_certificates" {
  description = "The list of cluster certificates."
  value       = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.*.cluster_certificates
}

output "cluster_certificate" {
  description = "The cluster certificate issued by the cluster's owner's issuing CA."
  value       = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.*.cluster_certificates.0.cluster_certificate
}

output "cluster_csr" {
  description = "The certificate signing request (CSR)."
  value       = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.*.cluster_certificates.0.cluster_csr
}

output "aws_hardware_certificate" {
  description = "The HSM hardware certificate issued by AWS CloudHSM."
  value       = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.*.cluster_certificates.0.aws_hardware_certificate
}

output "hsm_certificate" {
  description = "The HSM certificate issued by the HSM hardware."
  value       = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.*.cluster_certificates.0.hsm_certificate
}

output "manufacturer_hardware_certificate" {
  description = "The HSM hardware certificate issued by the hardware manufacturer."
  value       = aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.*.cluster_certificates.0.manufacturer_hardware_certificate
}

output "windows_codesign_instance_id" {
  value = aws_instance.windows_codesign_instance.*.id
}

output "windows_codesign_instance_private_ip" {
  value = aws_instance.windows_codesign_instance.*.private_ip
}

output "windows_codesign_instance_public_ip" {
  value = aws_instance.windows_codesign_instance.*.public_ip
}

output "windows_codesign_instance_ami" {
  value = aws_instance.windows_codesign_instance.*.ami
}
