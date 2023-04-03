#!/usr/bin/env bash

systemctl stop subspace.service
# disable the service
systemctl disable subspace.service
# delete the service file
rm  /etc/systemd/system/subspace.service
# update docker restart policy to no so that containers wont start.
docker ps -aq | xargs docker update --restart=no
# stop all the containers
docker ps -aq | xargs docker stop
# prune everything docker related
docker system prune -a -f --volumes
# seems like system prune is broken with docker 23.
# so we need to prune volumes manually. Remove the following when issue is fixed.
# TODO: https://github.com/docker/cli/issues/4028
docker volume prune -f --filter all=1
