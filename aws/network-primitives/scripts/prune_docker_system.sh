#!/usr/bin/env bash
sudo docker ps -aq | xargs sudo docker update --restart=no
# stop all the containers
sudo docker compose down -v 
# prune everything docker related
sudo docker system prune -a -f --volumes
sudo docker volume ls -q | xargs sudo docker volume rm -f
# remove key files
sudo rm -rf ~/subspace/*_keys.txt
