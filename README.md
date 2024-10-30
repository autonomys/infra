# Subspace Infrastructure.

This project declares the infrastructure currently used by Subspace Network.

We use **Terraform** and **AWS**. Any **project**, **instances**, **volume**, **attachment** must be defined in this repository to be reviewed and deployed using IAC.

Terraform projects folder structure:

```
resources
├── README.md
├── devnet
├── gemini-3h
├── leaseweb
├── mainnet
├── packer
├── taurus
└── telemetry
```

- If you need to **create a new project**:
    - go to the **resources** folder, 
    - create a **new folder-project**
    - use the terraform.tfvars.example from another project to populate the input variables
- Then you are ready to follow instructions to **init** terraform, **add resources**, **plan** the resource deployment and **apply** the resource deployments in **AWS**

_To apply any updates or new definitions_ you must always work in a separate branch and create a _Pull Request to the main branch_. 


## Pre requisites.

Install Terraform cli:

- https://learn.hashicorp.com/tutorials/terraform/install-cli

## Getting started.

Start by defining your personal AWS access and secret keys as an env variable, so you won’t have to set your token each time you run Terraform.

```
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
```

Go to **resources/PROJECT_NAME** directory and run the following commands to init terraform:

```
terraform init
```

You are ready to run the **plan** and **apply** command with this.

## Deploy resources.

In the **resources/PROJECT_NAME** directory, run the following commands:


1. Run the **plan** command with the variable values passed in to see Terraform's steps to deploy your project resources.

```SH
terraform plan -var-file terraform.tfvars -out current-plan.tfplan
```

2. Run the **apply** command with the generated **current-plan.tfplan**.

```SH
terraform apply "current-plan.tfplan"
```

Terraform will apply changes and generate/update the **.tfstate** file.
Be aware that state files can contain sensitive information. Do not expose it to the public repository.


Note: When creating a new workspace for a project, ensure to change plan execution from remote to local from the workspace->settings->Execution Mode.
Choose local so only the state is store and tracked and execution can be done from the local instead of terraform cloud. 
