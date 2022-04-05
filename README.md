# Subspace Infrastructure.

This project declares the infraestructure currently used by Subspace Network.

We are using **Terraform** and **DigitalOcean** as our main provider. 
Any **project**, **droplet**, **volume**, **attachment** must be defined in this repository to be reviewed and deployed.

Terraform projects are created under the `resources` folder using the following structure:

```
└──  resources
    └── aries-dev/
    └── aries-test-a/
    └── aries-test-b/
    └── polkadot-archive/
    └── status-page/
    └── telemetry/
    └── common.tf 
```

- `common.tf` is located on the resources folder, it contains all the definitions to be used for each project. 
- To re use common definitios a `symlink` is created using `/resources/common.tf` as the source.
- If you need to **create a new project**:
    - go to the **resources** folder, 
    - create a **new folder-project** 
    - link common definitions running `ln -s ../common.tf common.tf`. 
- Then you are ready to follow instructions to **init** terraform, **add resources**, **plan** the resource deployment and **apply** the resource deployments in **DigitalOcean**

_To apply any updates or new definitions_ you must always work in a separate branch and create a _Pull Request to the main branch_. 


## Pre requisites.

Install Terraform cli:

- https://learn.hashicorp.com/tutorials/terraform/install-cli

## Getting started.

Start by defining your personal DigitalOcean access token as an env variable, so you won’t have to set your token each time you run Terraform.
You can find your API token in your [DigitalOcean](https://cloud.digitalocean.com/account/api/tokens) account.

```
export DO_TOKEN=9999999999999999aaaaaaaaaaaaaaa
```

Go to **resources/PROJECT_NAME** directory and run the following commands to init terraform:

```
terraform init
```

With this, you are ready to run the **plan** and **apply** command.

### Deploy resources.

In the **resources/PROJECT_NAME** directory, run the following commands:

1. Run the **plan** command with the variable values passed in to see what steps Terraform would take to deploy your project resources.

```SH
terraform plan -var "do_token=${DO_TOKEN}" -out current-plan.tfplan
# DO NOT FORGET TO EXPORT DO_TOKEN before running this command. 
```

2- Run the **apply** command with the generated **current-plan.tfplan**.

```SH
terraform apply "current-plan.tfplan"
```

Terraform will apply changes and generate/update the **.tfstate** file.
Be aware that state files can contain sensitive information. Do not expose it to the public repository.
