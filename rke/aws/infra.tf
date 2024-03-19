# AWS infrastructure resources

# AWS EC2 instance for creating a single node RKE cluster and installing the Rancher server
resource "aws_instance" "rancher_server" {
  depends_on = [
    aws_route_table_association.rancher_route_table_association
  ]
  ami           = data.aws_ami.ubuntu_amd64.id
  instance_type = var.instance_type

  key_name                    = aws_key_pair.subspace_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.rancher_sg_allow.id]
  subnet_id                   = aws_subnet.rancher_subnet.id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 40
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = {
    Name    = "${var.prefix}-rancher-server"
    Creator = "rancher-${var.prefix}"
  }
}

# Rancher resources
module "rancher_common" {
  source = "../rancher-common"

  node_public_ip             = aws_instance.rancher_server.public_ip
  node_internal_ip           = aws_instance.rancher_server.private_ip
  node_username              = local.node_username
  ssh_private_key_pem        = tls_private_key.global_key.private_key_pem
  rancher_kubernetes_version = var.rancher_kubernetes_version

  cert_manager_version    = var.cert_manager_version
  rancher_version         = var.rancher_version
  rancher_helm_repository = var.rancher_helm_repository

  rancher_server_dns = join(".", ["rancher", aws_instance.rancher_server.public_ip, "sslip.io"])

  admin_password = var.rancher_server_admin_password

  workload_kubernetes_version = var.workload_kubernetes_version
  workload_cluster_name       = "${var.prefix}_workload"
}

# AWS EC2 instance for creating a single node workload cluster
resource "aws_instance" "subspace_workload" {
  depends_on = [
    aws_route_table_association.rancher_route_table_association
  ]
  ami           = data.aws_ami.ubuntu_amd64.id
  instance_type = var.instance_type

  key_name                    = aws_key_pair.subspace_key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.rancher_sg_allow.id]
  subnet_id                   = aws_subnet.rancher_subnet.id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 40
  }

  user_data = templatefile(
    "${path.module}/files/userdata_node.template",
    {
      register_command = module.rancher_common.custom_cluster_command
    }
  )

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = {
    Name    = "${var.prefix}-worker-node"
    Creator = "${var.prefix}"
  }
}
