locals {
  ips = [digitalocean_droplet.x-net-rpc.ipv4_address, digitalocean_droplet.x-net-farmer.ipv4_address, digitalocean_droplet.x-net-executor.ipv4_address]
}

resource "null_resource" "node_keys" {
  # trigger on new ipv4 change for any instance since we would need to update reserved ips
  triggers = {
    cluster_instance_ipv4s = join(",", local.ips)
  }

  # generate node keys
  provisioner "local-exec" {
    command = "../../scripts/generate_node_keys.sh 3 ./node_keys.txt"
    interpreter = [ "/bin/bash", "-c" ]
    environment = {
      NODE_PUBLIC_IPS = join(",", local.ips)
    }
  }
}

resource "null_resource" "setup_nodes" {
  count = length(local.ips)

  depends_on = [null_resource.node_keys, cloudflare_record.x-net-rpc]

  # trigger on node ip changes
  triggers = {
    cluster_instance_ipv4s = join(",", local.ips)
  }

  connection {
    host = local.ips[count.index]
    user = "root"
    type = "ssh"
    agent = true
    agent_identity = var.ssh_identity
    timeout = "2m"
  }

  # create subspace dir
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

  # install docker and docker compose
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /subspace/install_docker.sh",
      "sudo /subspace/install_docker.sh"
    ]
  }

}
