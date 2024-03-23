#!/bin/bash
# NOTE: uncomment when running first time to initialize the vault cluster / make sure to comment out after to avoid re-initializing the vault cluster
#kubectl exec vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
sleep 5
VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec vault-0 -n vault -- vault status
# join the vault cluster
cat cluster-keys.json | jq -r ".root_token"
CLUSTER_ROOT_TOKEN=$(cat cluster-keys.json | jq -r ".root_token")
kubectl exec vault-0 -n vault -- vault login $CLUSTER_ROOT_TOKEN

# List all the nodes within the Vault cluster for the vault-0 pod
kubectl exec vault-0 -n vault -- vault operator raft list-peers
# Join the Vault server on vault-1 to the Vault cluster
kubectl exec vault-1 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
# Join the Vault server on vault-2 to the Vault cluster
kubectl exec vault-2 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY

kubectl exec vault-0 -n vault -- vault operator raft list-peers
kubectl get pods -n vault | grep vault

exit $?
