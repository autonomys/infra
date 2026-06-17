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

  provisioner "remote-exec" {
    inline = [
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
