# Terraform-Based Testing Framework for Subspace Infrastructure

## Introduction

Welcome to the Terraform-based testing framework for Subspace's devnets. This framework does devnet infrastructure deployments using Terraform based on the developers branch by building and deploying with docker & docker compose, on either AWS or Hetzner metal.

## Prerequisites

Before using this framework, ensure you have the following installed:

- [Terraform (latest version recommended)](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Git
- [AWS CLI (required when deploying on AWS only)](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)

## Installation via Terraform

We use **Terraform**, **AWS**, or **Hetzner Metal** to provision the infrastructure.

Clone the repository and navigate to the testing framework directory **testing-framework**:

### Terraform Testing Framework Folder Structure:

```
.
├── README.md
├── ec2
│   ├── base
│   │   ├── ami.tf
│   │   ├── bootstrap_node_provisioner.tf
│   │   ├── domain_node_provisioner.tf
│   │   ├── farmer_node_provisioner.tf
│   │   ├── instances.tf
│   │   ├── network.tf
│   │   ├── node_provisioner.tf
│   │   ├── outputs.tf
│   │   ├── provider.tf
│   │   ├── scripts
│   │   └── variables.tf
│   └── network
│       ├── backend.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfvars.example
│       └── variables.tf
└── hetzner
    ├── base
    │   ├── bootstrap_node_provisioner.tf
    │   ├── domain_node_provisioner.tf
    │   ├── farmer_node_provisioner.tf
    │   ├── node_provisioner.tf
    │   ├── outputs.tf
    │   ├── scripts
    │   └── variables.tf
    └── network
        ├── backend.tf
        ├── main.tf
        ├── outputs.tf
        ├── terraform.tfvars.example
        └── variables.tf
```

## Getting started.

- To apply any updates or new definitions you must always work in a separate branch, by creating a new branch, i.e `bob/devnet`
- Go to **testing-framework/PROVIDER/network**
- rename the terraform.tfvars.example file inside the child module to terraform.tfvars.
- modify the main.tf file if any further changes are needed to customize
- If using AWS add your personal AWS access and secret in the terraform.tfvars file
- gather the necessary deployment ssh keys i.e deployer.pem or hetzner from bitwarden and set the `private_key_path` variable to the location on the filesystem.
- add the `branch_name` in the tfvars file of the branch you wish to deploy for terraform to build your code with docker.
- populate the empty variables with the correct values in the terraform.tfvars file, for the dedicated machines, add the ip address values. i.e

  ```
  additional_node_ips = {
    bootstrap = ["1.1.1.1"]
    node      = ["2.2.2.2"]
    farmer    = ["3.3.3.3"]
    domain    = ["4.4.4.4"]
  }
  ```

- modify the `backend.tf` file in the network folder of the module, by setting the workspace name i.e `"ephemeral-devnet-hetzner"` to include a suffix with your name, i.e `"ephemeral-devnet-hetzner-bob"` to prevent your backend from being shared with other developers. For AWS `"ephemeral-devnet-bob"`.

- Then you are ready to follow instructions to **init** terraform, **add resources**, **plan** the resource deployment and **apply** the resource deployments for the respective provider.

## Generate Node keys

Each devnet will need it's own keys, but if there are none deployed, you can re-use the default keys in bitwarden, extract the zip folder and copy all files/folders into **testing-framework/PROVIDER/network** path. The files should be named the following.

```
.
├── bootstrap_node_keys.txt
├── domain_node_keys.txt
├── dsn_bootstrap_node_keys.txt
├── farmer_node_keys.txt
├── full_node_keys.txt
├── keystore
├── relayer_ids.txt
└── rpc_node_keys.txt
```

Note: if you need to create new ones, the format of the files should be the same, so it works with the scripts.

## Deploy resources.

1. Go to **testing-framework/PROVIDER/network** directory and run the following commands to init terraform:

   ```
   terraform init
   ```

   You are ready to run the **plan** and **apply** command with this.

2. Run the **plan** command with the variable values passed in to see Terraform's steps to deploy your project resources.

   ```SH
   terraform plan -var-file=terraform.tfvars -out current-plan.tfplan
   ```

3. Run the **apply** command with the generated **current-plan.tfplan**.

   ```SH
   terraform apply current-plan.tfplan
   ```

Terraform will apply changes and generate/update the **.tfstate** file.
Be aware that state files can contain sensitive information. Do not expose it to the public repository.

## Installation via Github Actions

(coming soon)
