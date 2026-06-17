resource "null_resource" "deploy_uptime_kuma" {
  depends_on = [aws_instance.telemetry]

  # redeploy when the compose changes or the box is replaced
  triggers = {
    compose_sha = filesha256("${path.module}/uptime-kuma/docker-compose.yml")
    instance_id = aws_instance.telemetry.id
  }

  connection {
    host    = aws_instance.telemetry.public_ip
    user    = var.ssh_user
    type    = "ssh"
    agent   = true
    timeout = "120s"
  }

  # on a fresh/replaced box: wait for cloud-init and install docker if missing (no-op on the existing box)
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait 2>/dev/null || true",
      "command -v docker >/dev/null 2>&1 || { curl -fsSL https://get.docker.com | sudo sh; }",
      "mkdir -p /home/${var.ssh_user}/uptime-kuma/docker",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/uptime-kuma/docker-compose.yml"
    destination = "/home/${var.ssh_user}/uptime-kuma/docker/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.ssh_user}/uptime-kuma/docker && sudo docker compose up -d",
    ]
  }
}
