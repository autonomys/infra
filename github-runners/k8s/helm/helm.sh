#!/bin/sh

#export GITHUB_TOKEN=$1
echo $GITHUB_TOKEN
kubectl create secret generic controller-manager  -n actions-runner-system --from-literal=github_token=${GITHUB_TOKEN}
helm upgrade --install --namespace actions-runner-system  --create-namespace --wait actions-runner-controller actions-runner-controller/actions-runner-controller --set syncPeriod=1m
