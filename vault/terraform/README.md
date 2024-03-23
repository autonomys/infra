# Amazon Web Services

Export global variables

```shell
export AWS_PROFILE=<MY_PROFILE>
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-west-2
export EKS_CLUSTER_NAME="vault"
export R53_HOSTED_ZONE_ID=<R53_HOSTED_ZONE_ID>
export ACM_VAULT_ARN=<ACM_VAULT_ARN>
export hosted_zone=<hosted_zone>
```

Initialize AWS vault infrastructure. The states will be saved in Terraform cloud.

```shell
terraform init
```

Complete `terraform.tfvars` and run

```shell
sed -i "s/<LOCAL_IP_RANGES>/$(curl -s http://checkip.amazonaws.com/)\/32/g; s/<hosted_zone>/${hosted_zone}/g; s/<AWS_ACCOUNT_ID>/${AWS_ACCOUNT_ID}/g; s/<AWS_REGION>/${AWS_REGION}/g; s/<EKS_CLUSTER_NAME>/${EKS_CLUSTER_NAME}/g; s,<ACM_VAULT_ARN>,${ACM_VAULT_ARN},g;" terraform.tfvars
terraform apply
```

Access the EKS Cluster using

```shell
aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
kubectl config set-context --current --namespace=vault-server
```

# Vault

Install [vault](https://learn.hashicorp.com/tutorials/vault/getting-started-install)

Vault reads these environment variables for communication. Set Vault's address, and the initial root token.

```shell
export VAULT_ADDR="https://vault.${hosted_zone}"
export VAULT_TOKEN="$(aws secretsmanager get-secret-value --secret-id $(terraform output vault_secret_name) --version-stage AWSCURRENT --query SecretString --output text | grep "Initial Root Token: " | awk -F ': ' '{print $2}')"
```

Create credentials:

```shell
ACCESS_KEY=ACCESS_KEY
SECRET_KEY=SECRET_KEY
PROJECT_NAME=gemini
vault secrets enable -path=subspace/projects/${PROJECT_NAME} -version=2 kv
vault kv put subspace/projects/${PROJECT_NAME}/credentials/access key="$ACCESS_KEY"
vault kv put subspace/projects/${PROJECT_NAME}/credentials/secret key="$SECRET_KEY"
```

Create the policy named my-policy with the contents from stdin

```shell
vault policy write vault-policy - <<EOF
# Read-only permissions

path "subspace/projects/${PROJECT_NAME}/*" {
  capabilities = [ "read" ]
}

EOF
```

Create a token and add the vault-policy policy

```shell
VAULT_TOKEN=$(vault token create -policy=vault-policy | grep "token" | awk 'NR==1{print $2}')
vault kv get -field=key subspace/projects/${PROJECT_NAME}/credentials/access
vault kv get -field=key subspace/projects/${PROJECT_NAME}/credentials/secret
```
