#!/usr/bin/env bash
sudo docker ps -aq | xargs docker update --restart=no
# stop all the containers
sudo docker ps -aq | xargs docker stop
# prune everything docker related
sudo docker system prune -a -f --volumes
# seems like system prune is broken with docker 23.
# so we need to prune volumes manually. Remove the following when issue is fixed.
# TODO: https://github.com/docker/cli/issues/4028
sudo docker volume prune -f --filter all=1

# remove key files
sudo rm -rf ~/subspace/*_keys.txt
