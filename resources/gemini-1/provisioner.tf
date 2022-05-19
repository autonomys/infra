resource "null_resource" "node_keys" {
  # trigger on new ipv4 change for any instance since we would need to update reserved ips
  triggers = {
    cluster_instance_ipv4s = join(",", digitalocean_droplet.gemini-1.*.ipv4_address)
  }

  # generate node keys
  provisioner "local-exec" {
    command = "../../scripts/generate_node_keys.sh ${length(var.droplet-regions)} ./node_keys.txt"
    interpreter = [ "/bin/zsh", "-c" ]
    environment = {
      NODE_PUBLIC_IPS = join(",", digitalocean_droplet.gemini-1.*.ipv4_address)
    }
  }
}

resource "null_resource" "gemini-1" {
  count = length(var.droplet-regions)

  depends_on = [null_resource.node_keys, cloudflare_record.bootstrap, cloudflare_record.rpc]

  # trigger on new ipv4 change for any instance since we would need to update reserved ips
  triggers = {
    cluster_instance_ipv4s = join(",", digitalocean_droplet.gemini-1.*.ipv4_address)
  }

  connection {
    host = digitalocean_droplet.gemini-1[count.index].ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /subspace"
    ]
  }

  # copy install file
  provisioner "file" {
    source = "../../scripts/install_docker.sh"
    destination = "/subspace/install_docker.sh"
  }

  # copy node keys file
  provisioner "file" {
    source = "./node_keys.txt"
    destination = "/subspace/node_keys.txt"
  }

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /subspace/install_docker.sh",
      "sudo /subspace/install_docker.sh"
    ]
  }

  # copy compose file
  provisioner "file" {
    source = "../../services/gemini-1/install_compose_file.sh"
    destination = "/subspace/install_compose_file.sh"
  }

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      "echo NODE_SNAPSHOT_TAG=${var.node-snapshot-tag} >> /subspace/.env",
      "echo NODE_ID=${count.index} >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/node_keys.txt) >> /subspace/.env",
      "sudo chmod +x /subspace/install_compose_file.sh",
      "sudo /subspace/install_compose_file.sh ${length(digitalocean_droplet.gemini-1)}",
      "docker compose -f /subspace/docker-compose.yml up -d",
    ]
  }
}
