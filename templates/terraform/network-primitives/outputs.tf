// Output Variables

output "bootstrap_node_server_id" {
  value = aws_instance.bootstrap_node.*.id
}

output "bootstrap_node_public_ip" {
  value = aws_instance.bootstrap_node.*.public_ip
}

output "bootstrap_node_private_ip" {
  value = aws_instance.bootstrap_node.*.private_ip
}

output "bootstrap_node_ami" {
  value = aws_instance.bootstrap_node.*.ami
}

output "bootstrap_node_evm_server_id" {
  value = aws_instance.bootstrap_node_evm.*.id
}

output "bootstrap_node_evm_public_ip" {
  value = aws_instance.bootstrap_node_evm.*.public_ip
}

output "bootstrap_node_evm_private_ip" {
  value = aws_instance.bootstrap_node_evm.*.private_ip
}

output "bootstrap_node_evm_ami" {
  value = aws_instance.bootstrap_node_evm.*.ami
}

output "bootstrap_node_autoid_server_id" {
  value = aws_instance.bootstrap_node_autoid.*.id
}

output "bootstrap_node_autoid_public_ip" {
  value = aws_instance.bootstrap_node_autoid.*.public_ip
}

output "bootstrap_node_autoid_private_ip" {
  value = aws_instance.bootstrap_node_autoid.*.private_ip
}

output "bootstrap_node_autoid_ami" {
  value = aws_instance.bootstrap_node_autoid.*.ami
}

output "rpc_node_server_id" {
  value = aws_instance.rpc_node.*.id
}

output "rpc_node_private_ip" {
  value = aws_instance.rpc_node.*.private_ip
}

output "rpc_node_public_ip" {
  value = aws_instance.rpc_node.*.public_ip
}

output "rpc_node_ami" {
  value = aws_instance.rpc_node.*.ami
}

output "evm_node_server_id" {
  value = aws_instance.evm_node.*.id
}

output "evm_node_private_ip" {
  value = aws_instance.evm_node.*.private_ip
}

output "evm_node_public_ip" {
  value = aws_instance.evm_node.*.public_ip
}

output "evm_node_ami" {
  value = aws_instance.evm_node.*.ami
}

output "autoid_node_server_id" {
  value = aws_instance.autoid_node.*.id
}

output "autoid_node_private_ip" {
  value = aws_instance.autoid_node.*.private_ip
}

output "autoid_node_public_ip" {
  value = aws_instance.autoid_node.*.public_ip
}

output "autoid_node_ami" {
  value = aws_instance.autoid_node.*.ami
}

output "farmer_node_server_id" {
  value = aws_instance.farmer_node.*.id
}

output "farmer_node_private_ip" {
  value = aws_instance.farmer_node.*.private_ip
}

output "farmer_node_public_ip" {
  value = aws_instance.farmer_node.*.public_ip
}

output "farmer_node_ami" {
  value = aws_instance.farmer_node.*.ami
}

output "dns-records" {
  value = concat(
    [for record in cloudflare_dns_record.rpc : "${record.name}.${data.cloudflare_zone.cloudflare_zone.name}"],
    [for record in cloudflare_dns_record.bootstrap : "${record.name}.${data.cloudflare_zone.cloudflare_zone.name}"],
    [for record in cloudflare_dns_record.bootstrap_evm : "${record.name}.${data.cloudflare_zone.cloudflare_zone.name}"],
    [for record in cloudflare_dns_record.bootstrap_auto : "${record.name}.${data.cloudflare_zone.cloudflare_zone.name}"],
    [for record in cloudflare_dns_record.auto_evm : "${record.name}.${data.cloudflare_zone.cloudflare_zone.name}"],
    [for record in cloudflare_dns_record.autoid : "${record.name}.${data.cloudflare_zone.cloudflare_zone.name}"],
  )
}
