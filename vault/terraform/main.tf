resource "kubernetes_namespace" "vault-server" {
  metadata {
    name = "vault-server"
  }
}

data "template_file" "vault-values" {
  template = <<EOF
        global:
          tlsDisable: false
        ui:
          enabled: true
          externalPort: 443
          serviceType: "LoadBalancer"
          loadBalancerSourceRanges:
          - ${var.authorized_source_ranges}
          - ${aws_eip.nat["public-vault-1"].public_ip}/32
          - ${aws_eip.nat["public-vault-2"].public_ip}/32
          - ${aws_eip.nat["public-vault-3"].public_ip}/32
          annotations: |
            service.beta.kubernetes.io/aws-load-balancer-ssl-cert: ${var.acm_vault_arn}
            service.beta.kubernetes.io/aws-load-balancer-backend-protocol: https
            service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443,8200"
            service.beta.kubernetes.io/do-loadbalancer-healthcheck-path: "/ui/"
            service.beta.kubernetes.io/aws-load-balancer-internal: "false"
            external-dns.alpha.kubernetes.io/hostname: "vault.${var.hosted_zone}"
            external-dns.alpha.kubernetes.io/ttl: "30"
        server:
          nodeSelector: |
            eks.amazonaws.com/nodegroup: private-node-group-vault
          extraEnvironmentVars:
            VAULT_CACERT: /vault/userconfig/vault-server-tls/vault.ca
          extraVolumes:
          - type: secret
            name: vault-server-tls
          image:
            repository: "vault"
            tag: "1.6.0"
          logLevel: "debug"
          serviceAccount:
            annotations: |
              eks.amazonaws.com/role-arn: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/vault-unseal"
          extraEnvironmentVars:
            AWS_ROLE_SESSION_NAME: some_name
          ha:
            enabled: true
            nodes: 3
            raft:
              enabled: true
              setNodeId: true
              config: |
                ui = true

                listener "tcp" {
                  tls_disable = 0
                  tls_cert_file = "/vault/userconfig/vault-server-tls/vault.crt"
                  tls_key_file  = "/vault/userconfig/vault-server-tls/vault.key"
                  tls_client_ca_file = "/vault/userconfig/vault-server-tls/vault.ca"
                  address = "[::]:8200"
                  cluster_address = "[::]:8201"
                }

                storage "raft" {
                  path    = "/vault/data"
                }

                service_registration "kubernetes" {}

                seal "awskms" {
                  region     = "${var.region}"
                  kms_key_id = "${aws_kms_key.vault-kms.key_id}"
                }
   EOF
}

resource "helm_release" "vault" {
  name = "vault"

  chart  = "hashicorp/vault"
  values = [data.template_file.vault-values.rendered]

  namespace = "vault-server"

  depends_on = [kubernetes_job.vault-certificate]
}

resource "kubernetes_cluster_role" "boot-vault" {
  metadata {
    name = "boot-vault"
  }

  rule {
    api_groups = [""]
    resources  = ["pods/exec", "pods", "pods/log", "secrets", "tmp/secrets"]
    verbs      = ["get", "list", "create"]
  }

  rule {
    api_groups = ["certificates.k8s.io"]
    resources  = ["certificatesigningrequests", "certificatesigningrequests/approval"]
    verbs      = ["get", "list", "create", "update"]
  }
}

resource "kubernetes_service_account" "boot-vault" {
  metadata {
    name      = "boot-vault"
    namespace = "vault-server"
    labels = {
      "app.kubernetes.io/name" = "boot-vault"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.vault.arn
    }
  }
}

resource "kubernetes_job" "vault-initialization" {
  metadata {
    name      = "boot-vault"
    namespace = "vault-server"
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "boot-vault"
          image   = "amazonlinux"
          command = ["/bin/bash", "-c"]
          args    = ["sleep 15; yum install -y awscli 2>&1 > /dev/null; export AWS_REGION=${var.region}; aws sts get-caller-identity; aws s3 cp $(S3_SCRIPT_URL) ./script.sh; chmod +x ./script.sh; ./script.sh"]
          env {
            name  = "S3_SCRIPT_URL"
            value = "s3://${aws_s3_bucket.vault-scripts.id}/scripts/bootstrap.sh"
          }
          env {
            name  = "VAULT_SECRET"
            value = aws_secretsmanager_secret.vault-secret.arn
          }
        }
        service_account_name = "boot-vault"
        restart_policy       = "Never"
      }
    }
    backoff_limit = 0
  }

  depends_on = [
    kubernetes_job.vault-certificate,
    helm_release.vault,
    aws_s3_bucket_object.vault-script-bootstrap
  ]
}

resource "kubernetes_job" "vault-certificate" {
  metadata {
    name      = "certificate-vault"
    namespace = "vault-server"
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "certificate-vault"
          image   = "amazonlinux"
          command = ["/bin/bash", "-c"]
          args    = ["sleep 15; yum install -y awscli 2>&1 > /dev/null; export AWS_REGION=${var.region}; export NAMESPACE='vault-server'; aws sts get-caller-identity; aws s3 cp $(S3_SCRIPT_URL) ./script.sh; chmod +x ./script.sh; ./script.sh"]
          env {
            name  = "S3_SCRIPT_URL"
            value = "s3://${aws_s3_bucket.vault-scripts.id}/scripts/certificates.sh"
          }
        }
        service_account_name = "boot-vault"
        restart_policy       = "Never"
      }
    }
    backoff_limit = 0
  }

  depends_on = [
    aws_eks_node_group.private,
    aws_s3_bucket_object.vault-script-certificates
  ]
}

resource "kubernetes_cluster_role_binding" "boot-vault" {
  metadata {
    name = "boot-vault"
    labels = {
      "app.kubernetes.io/name" : "boot-vault"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "boot-vault"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "boot-vault"
    namespace = "vault-server"
  }
}

data "kubernetes_service" "vault-ui" {
  metadata {
    name      = "vault-ui"
    namespace = "vault-server"
  }
  depends_on = [
    kubernetes_job.vault-initialization,
    helm_release.vault
  ]
}
