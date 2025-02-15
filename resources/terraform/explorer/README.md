# Terraform-Based Deployment for Explorer Infrastructure

## Introduction

Welcome to the Terraform deployment guide for Subspace's explorers. This contains infrastructure provisioning using Terraform and deployments with docker & docker compose for explorer squids, subsquid archive, and blockscout backends.

## Prerequisites

Before using this guide, ensure you have the following installed:

- [Terraform (latest version recommended)](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Git
- [AWS CLI (required when deploying on AWS only)](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)

## Installation via Terraform

We use **Terraform** and **AWS** to provision the infrastructure.

Clone the repository and navigate to the explorer directory **explorer**:

### Terraform AWS Folder Structure:

```
.
├── README.md
└── terraform
    └── aws
        └── ec2
            └── gemini-3g
                ├── base
                │   ├── ami.tf
                │   ├── archive.tf
                │   ├── blockscout.tf
                │   ├── bootstrap_archive_provisioner.tf
                │   ├── bootstrap_blockscout_provisioner.tf
                │   ├── bootstrap_nova_archive_provisioner.tf
                │   ├── bootstrap_nova_squid_provisioner.tf
                │   ├── bootstrap_squid_provisioner.tf
                │   ├── common.tf
                │   ├── config
                │   │   ├── cors-settings.conf
                │   │   ├── nginx-archive.conf
                │   │   ├── nginx-blockscout.conf
                │   │   ├── nginx-squid.conf
                │   │   └── postgresql.conf
                │   ├── dns.tf
                │   ├── network.tf
                │   ├── outputs.tf
                │   ├── provider.tf
                │   ├── scripts
                │   │   ├── create_archive_node_compose_file.sh
                │   │   ├── create_nova_archive_node_compose_file.sh
                │   │   ├── create_nova_squid_node_compose_file.sh
                │   │   ├── create_squid_node_compose_file.sh
                │   │   ├── install_docker.sh
                │   │   └── install_nginx.sh
                │   ├── squids.tf
                │   ├── variables.tf
                │   └── volumes.tf.disabled
                └── modules
                    └── squids
                        ├── backend.tf
                        ├── main.tf
                        ├── outputs.tf
                        ├── terraform.tfvars
                        ├── terraform.tfvars.example
                        └── variables.tf
```

## Getting started.

- Go to **terraform/aws/ec2/<network_name>/modules/squid**
- rename the terraform.tfvars.example file inside the child module to terraform.tfvars.
- modify the main.tf file if any further changes are needed to customize
- Add your personal AWS access and secret in the terraform.tfvars file
- gather the necessary deployment ssh keys i.e explorer-deployer.pem from bitwarden and set the `private_key_path` variable to the location on the filesystem.
- populate the empty variables with the correct values in the terraform.tfvars file

- Then you are ready to follow instructions to **init** terraform, **add resources**, **plan** the resource deployment and **apply** the resource deployments for the respective provider.

## What is deployed

1. The terraform will deploy the blockexplorer squid, subsquid archive for both consensus and EVM domain, and blockscout for EVM domain.
2. Nginx is deployed as the web-server/reverse-proxy to serve requests to the backend stacks.
3. Certbot and auto-generation of the endpoints for the backends.
4. Docker and docker compose to run the stacks for each backend.
5. Postgres for both explorer squid and subsquid archive as a service in docker compose.

## Deploy resources.

1. Go to **terraform/aws/ec2/<network_name>/modules/squid** directory and run the following commands to init terraform:

   ```
   terraform init
   ```

   You are ready to run the **plan** and **apply** command with this.

2. Run the **plan** command with the variable values passed in to see Terraform's steps to deploy the project resources.

   ```SH
   terraform plan -var-file=terraform.tfvars -out current-plan.tfplan
   ```

3. Run the **apply** command with the generated **current-plan.tfplan**.

   ```SH
   terraform apply current-plan.tfplan
   ```

Terraform will apply changes and generate/update the **.tfstate** file.
Be aware that state files can contain sensitive information. Do not expose it to the public repository.
