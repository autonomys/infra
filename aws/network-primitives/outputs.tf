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


output "full_node_server_id" {
  value = aws_instance.full_node.*.id
}

output "full_node_private_ip" {
  value = aws_instance.full_node.*.private_ip
}

output "full_node_public_ip" {
  value = aws_instance.full_node.*.public_ip
}

output "full_node_ami" {
  value = aws_instance.full_node.*.ami
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


output "domain_node_server_id" {
  value = aws_instance.domain_node.*.id
}

output "domain_node_private_ip" {
  value = aws_instance.domain_node.*.private_ip
}

output "domain_node_public_ip" {
  value = aws_instance.domain_node.*.public_ip
}

output "domain_node_ami" {
  value = aws_instance.domain_node.*.ami
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
