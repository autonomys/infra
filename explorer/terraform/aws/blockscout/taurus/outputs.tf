output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.blockscout_taurus.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.blockscout_taurus.arn
}

output "instance_state" {
  description = "The current state of the instance"
  value       = aws_instance.blockscout_taurus.instance_state
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.blockscout_taurus.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.blockscout_taurus.public_ip
}

output "public_dns" {
  description = "Public DNS of the instance"
  value       = aws_instance.blockscout_taurus.public_dns
}

output "subnet_id" {
  description = "Subnet ID where the instance is running"
  value       = aws_instance.blockscout_taurus.subnet_id
}

output "vpc_security_group_ids" {
  description = "List of associated security groups"
  value       = aws_instance.blockscout_taurus.vpc_security_group_ids
}

output "key_name" {
  description = "Name of the key pair used to launch the instance"
  value       = aws_instance.blockscout_taurus.key_name
}

output "instance_type" {
  description = "The instance type of the EC2 instance"
  value       = aws_instance.blockscout_taurus.instance_type
}

output "cpu_core_count" {
  description = "Number of CPU cores"
  value       = aws_instance.blockscout_taurus.cpu_core_count
}

output "cpu_threads_per_core" {
  description = "Number of threads per core"
  value       = aws_instance.blockscout_taurus.cpu_threads_per_core
}

output "ebs_optimized" {
  description = "Indicates whether the instance is EBS optimized"
  value       = aws_instance.blockscout_taurus.ebs_optimized
}

output "root_volume_id" {
  description = "ID of the root EBS volume"
  value       = aws_instance.blockscout_taurus.root_block_device[0].volume_id
}

output "root_volume_size" {
  description = "Size of the root volume in GB"
  value       = aws_instance.blockscout_taurus.root_block_device[0].volume_size
}

output "root_volume_type" {
  description = "Type of the root volume (gp3, gp2, io1, etc.)"
  value       = aws_instance.blockscout_taurus.root_block_device[0].volume_type
}

output "root_volume_iops" {
  description = "IOPS of the root volume"
  value       = aws_instance.blockscout_taurus.root_block_device[0].iops
}

output "root_volume_throughput" {
  description = "Throughput of the root volume in MiB/s"
  value       = aws_instance.blockscout_taurus.root_block_device[0].throughput
}

output "instance_details_json" {
  description = "Complete instance details in JSON format"
  value       = jsonencode(aws_instance.blockscout_taurus)
}
