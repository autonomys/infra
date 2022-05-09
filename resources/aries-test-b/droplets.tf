# resource "digitalocean_droplet" "aries-test-b-nodes-farmer-relayer" {
#   image  = "ubuntu-20-04-x64"
#   name   = "aries-test-b-nodes-farmer-relayer"
#   region = "nyc3"
#   size   = "c-8"
#   ssh_keys = [
#     data.digitalocean_ssh_key.nazar-key.id,
#     data.digitalocean_ssh_key.serge-key.id,
#     data.digitalocean_ssh_key.leo-key.id,
#     # TODO: Add floating IP so that you can add this without changing the IP address
#     # data.digitalocean_ssh_key.sam-key.id,
#   ]
# }

resource "digitalocean_droplet" "aries-relaynet-test" {
  image  = "ubuntu-20-04-x64"
  name   = "aries-relaynet-a"
  region = "nyc3"
  size   = "c-8"
  ssh_keys = [
    data.digitalocean_ssh_key.nazar-key.id,
    data.digitalocean_ssh_key.serge-key.id,
    data.digitalocean_ssh_key.leo-key.id,
    data.digitalocean_ssh_key.sam-key.id,
  ]
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y && sudo apt-get upgrade -y",
      "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"",
      "apt-cache policy docker-ce",
      "sudo apt install -y docker-ce docker-compose nginx",
      "snap install core",
      "snap refresh core",
      "apt-get remove certbot -y",
      "snap install --classic certbot",
      "ln -s /snap/bin/certbot /usr/bin/certbot",
      "certbot certonly --nginx -d aries-relay-rpc-a.subspace.network  --non-interactive --agree-tos --email admin@subspace.network",
      "sudo usermod -aG docker $USER",
      "mkdir -p  kusama-relayer/config polkadot-relayer/config testnet",
      "mkdir -p /mnt/relaynet_test_volume/bootstrap-node /mnt/relaynet_test_volume/farmer-data /mnt/relaynet_test_volume/public-rpc-node /mnt/relaynet_test_volume/kusama-archives /mnt/relaynet_test_volume/polkadot-archives",
      "chown nobody:nogroup /mnt/relaynet_test_volume/bootstrap-node /mnt/relaynet_test_volume/farmer-data /mnt/relaynet_test_volume/public-rpc-node /mnt/relaynet_test_volume/kusama-archives /mnt/relaynet_test_volume/polkadot-archives",
    ]

    connection {
      type  = "ssh"
      host  = self.ipv4_address
      user  = "root"
      agent = true
    }
  }

  provisioner "file" {
    source      = "nginx.conf"
    destination = "/etc/nginx/nginx.conf"
    connection {
      type  = "ssh"
      host  = self.ipv4_address
      user  = "root"
      agent = true
    }
  }

  provisioner "file" {
    source      = "testnet/docker-compose.yml"
    destination = "testnet/docker-compose.yml"
    connection {
      type  = "ssh"
      host  = self.ipv4_address
      user  = "root"
      agent = true
    }
  }

  provisioner "file" {
    source      = "config.json"
    destination = "polkadot-relayer/config/config.json"
    connection {
      type  = "ssh"
      host  = self.ipv4_address
      user  = "root"
      agent = true
    }
  }

  provisioner "file" {
    source      = "polkadot/docker-compose.yml"
    destination = "polkadot-relayer/docker-compose.yml"
    connection {
      type  = "ssh"
      host  = self.ipv4_address
      user  = "root"
      agent = true
    }
  }

  provisioner "file" {
    source      = "config.json"
    destination = "kusama-relayer/config/config.json"
    connection {
      type  = "ssh"
      host  = self.ipv4_address
      user  = "root"
      agent = true
    }
  }

  provisioner "file" {
    source      = "kusama/docker-compose.yml"
    destination = "kusama-relayer/docker-compose.yml"
    connection {
      type  = "ssh"
      host  = self.ipv4_address
      user  = "root"
      agent = true
    }
  }
}

