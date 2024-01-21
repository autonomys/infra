#!/bin/bash
# This script is used to deploy Blockscout to a Kubernetes cluster using Helm.

set -e

helm repo add blockscout https://blockscout.github.io/helm-charts
helm repo update

helm install blockscout-stack-1.4.0 blockscout/blockscout-stack --namespace nova-blockscout --create-namespace --values ./custom-values.yaml

exit $?
