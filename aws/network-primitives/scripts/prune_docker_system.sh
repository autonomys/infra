#!/usr/bin/env bash

sudo systemctl stop subspace.service
# disable the service
sudo systemctl disable subspace.service
# delete the service file
sudo rm  /etc/systemd/system/subspace.service
# update docker restart policy to no so that containers wont start.
sudo docker ps -aq | xargs docker update --restart=no
# stop all the containers
sudo docker ps -aq | xargs docker stop
# prune everything docker related
sudo docker system prune -a -f --volumes
# seems like system prune is broken with docker 23.
# so we need to prune volumes manually. Remove the following when issue is fixed.
# TODO: https://github.com/docker/cli/issues/4028
sudo docker volume prune -f --filter all=1
