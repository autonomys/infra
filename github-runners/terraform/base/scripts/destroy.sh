#! /bin/bash

set -eu

echo "running clean up script to destroy current deployment environment."
./config.sh remove --token ${GH_TOKEN}
sudo rm -rf $USER/actions-runner
sudo rm -rf $USER/_work
exit 0
