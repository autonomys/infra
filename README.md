# Subspace Infraestructure.

This docs are for internal purposes, this project declares infrastructure over DigitalOcean using Terraform.

- 2 projects: Development and Testing environments for Aries testing.
- 2 droplets: For now, 1 droplet for environment, each droplet should contains a bootnode, public rpc node, farmer node and a relayer backend configured to import parachain blocks from the attached extra volume.
- 2 volumes: Attached to each droplet, each volume should contains a data directory for each parachain to be imported from genesis.

For detailed information, please refer to the **[\_docs](./_docs/index.md)** folder.

Terraform structure:

```
.
└── tf/
    ├── resources
        ├── data-sources.tf
        ├── droplets.tf
        ├── outputs.tf
        ├── project.tf
        ├── provider.tf
        ├── variables.tf
        ├── versions.tf
        ├── volumes.tf
        └── external/
            └── name-generator.py
```

# Pre requisites.

Install Terraform cli:

- https://learn.hashicorp.com/tutorials/terraform/install-cli

# Getting started.

Start by defining your personal DigitalOcean access token as environment variables, so you won’t have to copy the values each time you run Terraform.
You can find your API token in your [DigitalOcean](https://cloud.digitalocean.com/account/api/tokens) account.

```
export DO_TOKEN=9999999999999999aaaaaaaaaaaaaaa
```

Go to **resources** directory and run the following commands to init terraform:

```
terraform init
```

With this, you are ready to run the **plan** and **apply** command.

## Deploy resources.

In the **resources** directory, run the following commands:

Run the **plan** command with the variable values passed in to see what steps Terraform would take to deploy your project.

```
terraform plan -var "do_token=${DO_TOKEN}" -out current-plan.tfplan
```

The Run the **apply** command with the current-plan.tfplan file to apply the exact changes reported in the plan.

```
terraform apply "current-plan.tfplan"
```

This will create projects, droplets and attached volumes declared in this project.

Initializing for now a **development** and a **testing** environments.

# TODO

A list of tasks to be automated. All this task are defined in detail in the **\_docs** folder and will be transformed to scripts files to be automated as we need.

- System settings

  - create a first sudo user for administration.
  - add auth ssh keys for the user remote ssh login.

- Auto install and configure with sudo user.

  - docker.
  - nginx.
  - certbot.
  - node 16.
  - pm2.

- Run workflows.

  - download blocks to relayer backend data volume.
  - get docker images for subspace network.
  - get docker images for datadog integration.
  - start bootnode, public-rpc, farmer.
  - start relayer for parachains genesis import.
  - start relayer for parachains live import.
  - start datadog agent to send logs to datadog.

- Next environments

  - staging.
  - production.

- Next improvements.

  - bootnode, public-rpc, farmer, relayer in separated droplet instances.
  - farmer droplet dedicated volume.
  - droplet for block downloader.
