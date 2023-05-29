#!/bin/bash
action=$1
eth0=$(ip -o -4 route show to default | grep -E -o 'dev [^ ]*' | awk 'NR==1{print $2}')

case $action in
pre-start)
  sudo docker compose -f /subspace/docker-compose.yml down
  ;;
start|restart)
  sudo docker compose -f /subspace/docker-compose.yml up -d --remove-orphans || exit 1
  ;;
post-start)
  sudo iptables -I FORWARD -o "${eth0}" -d 192.168.0.0/16,172.16.0.0/12,10.0.0.0/8 -j DROP
  sudo iptables -I OUTPUT -o "${eth0}" -d 192.168.0.0/16,172.16.0.0/12,10.0.0.0/8 -j DROP
  ;;
stop)
  sudo docker compose -f /subspace/docker-compose.yml down
  ;;
post-stop)
  sudo iptables -D FORWARD -o "${eth0}" -d 192.168.0.0/16,172.16.0.0/12,10.0.0.0/8 -j DROP
  sudo iptables -D OUTPUT -o "${eth0}" -d 192.168.0.0/16,172.16.0.0/12,10.0.0.0/8 -j DROP
esac
exit 0
