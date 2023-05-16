#Linux x86_64 runner
resource "aws_instance" "linux_x86_runner" {
  count             = length(var.public_subnet_cidrs)
  ami               = data.aws_ami.ubuntu_x86.image_id
  instance_type     = element(var.instance_type, 1)
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.allow_runner.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    name       = "gh-linux-x86-runner"
    role       = "runner"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "x86_64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.gw
  ]

  lifecycle {

    create_before_destroy = true

  }

  provisioner "file" {
    source      = "./scripts/secure.sh"
    destination = "/home/ubuntu/secure.sh"
  }

  provisioner "file" {
    source      = "./scripts/cleanup.sh"
    destination = "/home/ubuntu/cleanup.sh"
  }

  # # Github runner installation
  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -y",
      "sudo apt upgrade -y",
      "sudo apt install git curl wget gnupg openssl make build-essential jq net-tools -y",
      "sudo curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly -y",
      # Download runner image
      "mkdir actions-runner && cd actions-runner",
      "curl -o actions-runner-linux-x64-2.304.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.304.0/actions-runner-linux-x64-2.304.0.tar.gz",
      "echo '292e8770bdeafca135c2c06cd5426f9dda49a775568f45fcc25cc2b576afc12f  actions-runner-linux-x64-2.304.0.tar.gz' | shasum -a 256 -c",
      "tar xzf ./actions-runner-linux-x64-2.304.0.tar.gz",
      # configure runner
      "./config.sh --url https://github.com/subspace --token ${var.gh_token} --unattended --name linux_x86_64 --labels 'self-hosted,Linux,X64' --work _work --runasservice",
      "sudo ./svc.sh install",
      "sudo ./svc.sh start",
      "sudo ./svc.sh status",
      # install monitoring
      "sudo wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --non-interactive --nightly-channel --claim-token ${var.netdata_token} --claim-url https://app.netdata.cloud",

    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = "ubuntu"
    private_key = file("${var.public_key_path}")
    timeout     = "90s"
  }

}

resource "aws_instance" "linux_arm_runner" {
  count             = length(var.public_subnet_cidrs)
  ami               = data.aws_ami.ubuntu_arm64.image_id
  instance_type     = element(var.instance_type_arm, 0)
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.allow_runner.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    name       = "gh-linux-arm64-runner"
    role       = "runner"
    os_name    = "ubuntu"
    os_version = "22.04"
    arch       = "arm64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.gw
  ]

  lifecycle {

    create_before_destroy = true

  }

  provisioner "file" {
    source      = "./scripts/secure.sh"
    destination = "/home/ubuntu/secure.sh"
  }

  provisioner "file" {
    source      = "./scripts/cleanup.sh"
    destination = "/home/ubuntu/cleanup.sh"
  }

  # Github runner installation
  provisioner "remote-exec" {
    inline = [
      "sleep 120",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt update -y",
      "sudo apt upgrade -y",
      "sudo apt install git curl wget gnupg openssl make build-essential jq net-tools -y",
      # Download runner image
      "mkdir actions-runner && cd actions-runner",
      "curl -o actions-runner-linux-arm64-2.304.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.304.0/actions-runner-linux-arm64-2.304.0.tar.gz",
      "echo '34c49bd0e294abce6e4a073627ed60dc2f31eee970c13d389b704697724b31c6  actions-runner-linux-arm64-2.304.0.tar.gz' | shasum -a 256 -c",
      "tar xzf ./actions-runner-linux-arm64-2.304.0.tar.gz",
      # configure runner
      "./config.sh --url https://github.com/subspace --token ${var.gh_token} --unattended --name linux_arm64 --labels 'self-hosted,Linux,ARM64' --work _work --runasservice",
      "sudo ./svc.sh install",
      "sudo ./svc.sh start",
      "sudo ./svc.sh status",
      # install monitoring
      "sudo wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --non-interactive --nightly-channel --claim-token ${var.netdata_token} --claim-url https://app.netdata.cloud",
    ]

    on_failure = continue

  }

  # Setting up the ssh connection
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = "ubuntu"
    private_key = file("${var.public_key_path}")
    timeout     = "90s"
  }
}

resource "aws_instance" "mac_x86_runner" {
  count             = length(var.public_subnet_cidrs)
  ami               = data.aws_ami.mac_x86.image_id
  instance_type     = element(var.instance_type_mac, 0)
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index + 1)
  tenancy           = "host"
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.allow_runner.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    name       = "gh-macos-x86-runner"
    role       = "runner"
    os_name    = "macos"
    os_version = "12"
    os_name    = "Monterey"
    arch       = "x86"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.gw
  ]

  lifecycle {

    create_before_destroy = true

  }

  provisioner "file" {
    source      = "./scripts/secure.sh"
    destination = "/home/ec2-user/secure.sh"
  }

  provisioner "file" {
    source      = "./scripts/cleanup.sh"
    destination = "/home/ec2-user/cleanup.sh"
  }

  # Github runner installation
  provisioner "remote-exec" {
    inline = [
      "sleep 160",
      "mkdir actions-runner && cd actions-runner",
      "curl -o actions-runner-osx-x64-2.304.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.304.0/actions-runner-osx-x64-2.304.0.tar.gz",
      "echo '26dddab8eafc193bb8b27afc5844ff3a6f789a655aca5bf79b018493963681a7  actions-runner-osx-x64-2.304.0.tar.gz' | shasum -a 256 -c",
      "tar xzf ./actions-runner-osx-x64-2.304.0.tar.gz",
      "./config.sh --url https://github.com/subspace --token ${var.gh_token} --unattended --name mac_x86_64 --labels 'self-hosted,MacOS,X64' --work _work --runasservice",
      "sudo ./run.sh",
      "curl https://my-netdata.io/kickstart.sh > /tmp/netdata-kickstart.sh && sh /tmp/netdata-kickstart.sh --non-interactive --nightly-channel --claim-token ${var.netdata_token} --claim-url https://app.netdata.cloud",
    ]

    on_failure = continue

  }

  # Setting up the ssh connection to install the runner server
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = "ec2-user"
    private_key = file("${var.public_key_path}")
    timeout     = "90s"
  }

}


resource "aws_instance" "mac_arm64_runner" {
  count             = length(var.public_subnet_cidrs)
  ami               = data.aws_ami.mac_arm64.image_id
  instance_type     = element(var.instance_type_mac, 1)
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index + 1)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.allow_runner.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true
  tenancy                     = "host"

  tags = {
    name       = "gh-macos-arm64-runner"
    role       = "runner"
    os_name    = "macos"
    os_version = "12"
    os_name    = "Monterey"
    arch       = "arm64"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.gw
  ]

  lifecycle {

    create_before_destroy = true

  }

  provisioner "file" {
    source      = "./scripts/secure.sh"
    destination = "/home/ec2-user/secure.sh"
  }

  provisioner "file" {
    source      = "./scripts/cleanup.sh"
    destination = "/home/ec2-user/cleanup.sh"
  }

  # Github runner installation
  provisioner "remote-exec" {
    inline = [
      "sleep 160",
      "mkdir actions-runner && cd actions-runner",
      "curl -o actions-runner-osx-x64-2.304.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.304.0/actions-runner-osx-arm64-2.304.0.tar.gz",
      "echo '26dddab8eafc193bb8b27afc5844ff3a6f789a655aca5bf79b018493963681a7  actions-runner-osx-arm64-2.304.0.tar.gz' | shasum -a 256 -c",
      "tar xzf ./actions-runner-osx-arm64-2.304.0.tar.gz",
      "./config.sh --url https://github.com/subspace --token ${var.gh_token} --unattended --name mac_arm64 --labels 'self-hosted,MacOS,ARM64' --work _work --runasservice",
      "sudo ./run.sh",
      "curl https://my-netdata.io/kickstart.sh > /tmp/netdata-kickstart.sh && sh /tmp/netdata-kickstart.sh --non-interactive --nightly-channel --claim-token ${var.netdata_token} --claim-url https://app.netdata.cloud",
    ]

    on_failure = continue

  }

  # Setting up the ssh connection to install the runner server
  connection {
    type        = "ssh"
    host        = element(self.*.public_ip, count.index)
    user        = "ec2-user"
    private_key = file("${var.public_key_path}")
    timeout     = "90s"
  }

}


resource "aws_instance" "windows_runner" {
  count             = length(var.public_subnet_cidrs)
  ami               = data.aws_ami.windows.image_id
  instance_type     = element(var.instance_type, 1)
  subnet_id         = element(aws_subnet.public_subnets.*.id, count.index)
  availability_zone = element(var.azs, count.index)
  # Security Group
  vpc_security_group_ids = ["${aws_security_group.allow_runner.id}"]
  # the Public SSH key
  key_name                    = var.aws_key_name
  associate_public_ip_address = true

  tags = {
    name       = "gh-windows-runner"
    role       = "runner"
    os_name    = "windows"
    os_version = "Microsoft Windows Server 2022 "
    arch       = "x86"
  }

  depends_on = [
    aws_subnet.public_subnets,
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.gw
  ]

  lifecycle {
  
    create_before_destroy = true

  }

  # Github runner installation
  provisioner "remote-exec" {
    inline = [
      # Download runner image
      "mkdir actions-runner && cd actions-runner",
      "Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.304.0/actions-runner-win-x64-2.304.0.zip -OutFile actions-runner-win-x64-2.304.0.zip",
      "if((Get-FileHash -Path actions-runner-win-x64-2.304.0.zip -Algorithm SHA256).Hash.ToUpper() -ne 'fbbddd2f94b195dde46aa6028acfe873351964c502aa9f29bb64e529b789500b'.ToUpper()){ throw 'Computed checksum did not match' }",
      "Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory(\"$PWD/actions-runner-win-x64-2.304.0.zip\", \"$PWD\")",
      # configure runner
      "./config.cmd --url https://github.com/subspace --token ${var.gh_token} --unattended --name windows_x86_64 --labels 'self-hosted,Linux,X64' --work _work --runasservice",
      "./run.cmd",
    ]

    on_failure = continue
  }

  connection {
    type     = "winrm"
    user     = "Administrator"
    password = "${var.win_admin_password}"
    host        = element(self.*.public_ip, count.index)
    insecure    = true                       # Set to true if using a self-signed certificate or invalid SSL/TLS certificate
    timeout     = "5m"                      # Specify the timeout value for the connection
    port        = 5986                       # Set the WinRM port number (default is 5986)
  }
}
