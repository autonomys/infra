#!/usr/bin/env bash

claim_token=${1}
claim_rooms=${2}
hostname=${3}

# set hostname
hostnamectl set-hostname "${hostname}"

# stop any running agent
systemctl stop netdata

curl https://my-netdata.io/kickstart.sh > /tmp/netdata-kickstart.sh && \
 sh /tmp/netdata-kickstart.sh --non-interactive --reinstall-clean --claim-token "${claim_token}" --claim-url https://app.netdata.cloud --claim-rooms "${claim_rooms}"
