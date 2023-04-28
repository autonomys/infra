resource "aws_instance" "linux-runner" {
  count                  = length(var.private_subnet_cidrs)
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnets[count.index].id
  availability_zone      = var.azs[0]
# Security Group
  vpc_security_group_ids = ["${aws_security_group.allow_runner.id}"]
# the Public SSH key
  key_name = var.aws_key_name

  tags = {
    name       = "gh-linux-runner"
    role       = "runner"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets
  ]

  lifecycle {
    # ignore_changes = [
    #   tags, ami
    # ]
    create_before_destroy = true

    //ignore_changes = all
  }

}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# resource "aws_instance" "web-server" {
#   #ami = lookup(var.ec2_ami, var.region)
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = var.instance_type
#   key_name      = var.aws_key_name
#   #count         = var.instance_count

#   network_interface {
#     device_index         = 0
#     network_interface_id = aws_network_interface.web-server-nic.id
#   }

#   depends_on = [
#     aws_network_interface.web-server-nic
#   ]

#   tags = {
#     #Name = "Nginx-web-${count.index}"
#     Name = "Nginx-web"
#   }

#   user_data = <<-EOF

#     #!/bin/bash -ex
#     apt update -y
#     apt install ca-certificate nginx certbot python3-certbot-nginx -y
#     systemctl enable --now nginx
#     systemctl start nginx

#   EOF
# }

