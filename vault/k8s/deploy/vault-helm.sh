#!/bin/bash

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
--create-namespace \
--namespace cert-manager \
--set installCRDs=true

# ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
#helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace \
#--set installCRDs=true \
#--set controller.replicaCount=2 \
#--set controller.metrics.enabled=true

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault --values vault-values.yaml --namespace vault --create-namespace \
--set server.ha.enabled=true \
--set server.ha.raft.enabled=true

helm status vault -n vault

kubectl apply -f vault-ingress.yaml
kubectl apply -f ../letsencrypt/clusterissuer.yaml
kubectl apply -f ../letsencrypt/secrets.secret.yaml
kubectl get pods -n vault | grep vault
bash vault-init.sh | tee vault-init.log

kubectl logs vault-0 -n vault -c vault -f # follow the logs
