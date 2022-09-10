#!/bin/bash

# updates
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt dist-upgrade -y
apt install -y curl jq

# install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt update -y
apt-cache -y policy docker-ce # this ensures that docker is installed from the docker repo instead of ubuntu repo
apt install -y docker-ce

# install docker-compose
curl -s -L "https://github.com/docker/compose/releases/download/$(curl -s -L https://api.github.com/repos/docker/compose/releases/latest | jq -r '.name')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# set max socket connections
if ! (grep -iq "net.core.somaxconn" /etc/sysctl.conf && sed -i 's/.*net.core.somaxconn.*/net.core.somaxconn=65535/' /etc/sysctl.conf); then
  echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
fi

sysctl -p /etc/sysctl.conf
