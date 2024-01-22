#!/bin/bash -e
# SERVICE is the name of the Vault service in Kubernetes.
# It does not have to match the actual running service, though it may help for consistency.
SERVICE=vault
SECRET_NAME=vault-server-tls
# TMPDIR is a temporary working directory.
TMPDIR=/tmp
# Sleep timer
SLEEP_TIME=15
# Name of the CSR
echo "Name the CSR: vault-csr"
export CSR_NAME=vault-csr

# Install OpenSSL
echo "Install openssl"
yum install -y openssl 2>&1

# Install Kubernetes cli
echo "Install Kubernetes cli"
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
kubectl version --short --client

# Create a private key
echo "Generate certificate Private key"
openssl genrsa -out ${TMPDIR}/vault.key 2048

# Create CSR
echo "Create CSR file"
cat <<EOF >${TMPDIR}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE}
DNS.2 = ${SERVICE}.${NAMESPACE}
DNS.3 = ${SERVICE}.${NAMESPACE}.svc
DNS.4 = ${SERVICE}.${NAMESPACE}.svc.cluster.local
DNS.5 = vault-0.vault-internal
DNS.6 = vault-1.vault-internal
DNS.7 = vault-2.vault-internal
IP.1 = 127.0.0.1
EOF

# Sign the CSR
echo "Sign the CSR"
openssl req -new -key ${TMPDIR}/vault.key -subj "/CN=${SERVICE}.${NAMESPACE}.svc" -out ${TMPDIR}/server.csr -config ${TMPDIR}/csr.conf

echo "Create a CSR Manifest file"
cat <<EOF >${TMPDIR}/csr.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  groups:
  - system:authenticated
  request: $(cat ${TMPDIR}/server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

echo "Create CSR from manifest file"
kubectl create -f ${TMPDIR}/csr.yaml

# TODO: Loop this till cert is signed
sleep ${SLEEP_TIME}
echo "Fetch the CSR from kubernetes"
kubectl get csr ${CSR_NAME}

# Approve Cert
echo "Approve the Certificate"
kubectl certificate approve ${CSR_NAME}

serverCert=$(kubectl get csr ${CSR_NAME} -n kubecf -o jsonpath='{.status.certificate}')
echo "${serverCert}" | openssl base64 -d -A -out ${TMPDIR}/vault.crt

# kubectl config view --raw -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${TMPDIR}/vault.ca
echo "Fetch Kubernetes CA Certificate"
kubectl get secret -o jsonpath="{.items[?(@.type==\"kubernetes.io/service-account-token\")].data['ca\.crt']}" | base64 --decode > ${TMPDIR}/vault.ca 2>/dev/null || true

echo "Create secret containing the TLS Certificates and key"
echo kubectl create secret generic ${SECRET_NAME} \
        --namespace ${NAMESPACE} \
        --from-file=vault.key=${TMPDIR}/vault.key \
        --from-file=vault.crt=${TMPDIR}/vault.crt \
        --from-file=vault.ca=${TMPDIR}/vault.ca

kubectl create secret generic ${SECRET_NAME} \
        --namespace ${NAMESPACE} \
        --from-file=vault.key=${TMPDIR}/vault.key \
        --from-file=vault.crt=${TMPDIR}/vault.crt \
        --from-file=vault.ca=${TMPDIR}/vault.ca
