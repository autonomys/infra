resource "null_resource" "gemini-1" {
  count = length(var.droplet-regions)

  connection {
    host = digitalocean_droplet.gemini-1[count.index].ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }

  # generate node keys
  provisioner "local-exec" {
    command = "../../scripts/generate_node_keys.sh ${length(var.droplet-regions)} ./node_keys.txt"
    environment = {
      NODE_PUBLIC_IPS = digitalocean_droplet.gemini-1[*].ipv4_address
    }
  }

  # copy install file
  provisioner "file" {
    source = "../../scripts/install_docker.sh"
    destination = "/subspace/install_docker.sh"
  }

  # copy compose file
  provisioner "file" {
    source = "../../services/gemini-1/docker-compose.yml"
    destination = "/subspace/docker-compose.yml"
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

  # start docker containers
  provisioner "remote-exec" {
    inline = [
      "echo NODE_SNAPSHOT_TAG=${var.node-snapshot-tag} >> /subspace/.env",
      "echo NODE_ID=${count.index} >> /subspace/.env",
      "echo NODE_KEY=$(sed -nr 's/NODE_${count.index}_KEY=//p' /subspace/node_keys.txt)",
      # TODO: additional args
      "docker compose up -f /subspace/docker-compose.yml -d",
    ]
  }
}
