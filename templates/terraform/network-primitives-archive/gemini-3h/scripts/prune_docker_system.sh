#!/usr/bin/env bash
sudo docker ps -aq | xargs sudo docker update --restart=no
# stop all the containers
sudo docker compose down
# prune everything docker related
sudo docker system prune -a -f
sudo docker volume ls -q | grep -v traefik | xargs sudo docker volume rm -f
# remove key files
sudo rm -rf ~/subspace/*_keys.txt
