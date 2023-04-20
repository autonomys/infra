#!/bin/bash

# updates
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt dist-upgrade -y
apt install -y curl jq gnupg

# install docker & Docker Compose
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update -y
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# set max socket connections
if ! (grep -iq "net.core.somaxconn" /etc/sysctl.conf && sed -i 's/.*net.core.somaxconn.*/net.core.somaxconn=65535/' /etc/sysctl.conf); then
  echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
fi

sysctl -p /etc/sysctl.conf
