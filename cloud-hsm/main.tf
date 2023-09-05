resource "aws_instance" "windows_codesign_instance" {
  count             = length(var.public_subnet_cidrs)
  ami               = data.aws_ami.windows_x86_64.image_id
  instance_type     = var.instance_type
  subnet_id         = element(aws_subnet.cloudhsm_public_subnet.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.cloudhsm_sg.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    name       = "windows-codesign"
    role       = "Windows HSM code signing"
    os_name    = "windows"
    os_version = "Microsoft Windows Server 2022 "
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.cloudhsm_public_subnet,
    aws_nat_gateway.cloudhsm_nat_gateway,
    aws_internet_gateway.cloudhsm_gw
  ]

  lifecycle {

    create_before_destroy = true

  }
}


resource "aws_cloudhsm_v2_cluster" "cloudhsm_v2_cluster" {
  count      = length(var.private_subnet_cidrs)
  hsm_type   = var.hsm_type
  subnet_ids = aws_subnet.cloudhsm_private_subnet.*.id

  tags = {
    Name = "aws_cloudhsm_v2_cluster"
  }
}

resource "aws_cloudhsm_v2_hsm" "cloudhsm_v2_hsm" {
  count      = length(var.private_subnet_cidrs)
  subnet_id  = element(aws_subnet.cloudhsm_private_subnet.*.id, count.index)
  cluster_id = element(aws_cloudhsm_v2_cluster.cloudhsm_v2_cluster.*.cluster_id, count.index)
  # availability_zone = element(var.azs, count.index)
}
