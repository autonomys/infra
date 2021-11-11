# Subspace Infrastructure.

This project declares infrastructure over DigitalOcean using Terraform.

For detailed information, please refer to the **[\_docs](./_docs/README.md)** folder.

Terraform structure:

```
.
└──  resources
    └── aries-dev/
    └── aries-test/
    └── external/
        └── name-generator.py
```

## Pre requisites.

Install Terraform cli:

- https://learn.hashicorp.com/tutorials/terraform/install-cli

## Getting started.

Start by defining your personal DigitalOcean access token as an env variable, so you won’t have to set your token each time you run Terraform.
You can find your API token in your [DigitalOcean](https://cloud.digitalocean.com/account/api/tokens) account.

```
export DO_TOKEN=9999999999999999aaaaaaaaaaaaaaa
```

Go to **resources/ENV** directory and run the following commands to init terraform:

```
terraform init
```

With this, you are ready to run the **plan** and **apply** command.

### Deploy resources.

In the **resources/ENV** directory, run the following commands:

Run the **plan** command with the variable values passed in to see what steps Terraform would take to deploy your project resources.

```
terraform plan -var "do_token=${DO_TOKEN}" -out current-plan.tfplan
```

Run the **apply** command with the generated **current-plan.tfplan**.

```
terraform apply "current-plan.tfplan"
```

Terraform will apply changes and generate/update the **.tfstate** file.
Be aware that state files can contain sensitive information. Do not expose it to the public repository.
