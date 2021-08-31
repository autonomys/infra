# terraform-do-droplets

Structure:

```
.
└── tf/
    ├── versions.tf
    ├── variables.tf
    ├── provider.tf
    ├── droplets.tf
    ├── dns.tf
    ├── data-sources.tf
    └── external/
    └── name-generator.py
```

# Getting started.

Start by defining the domain name, SSH key fingerprint, and your personal access token as environment variables, so you won’t have to copy the values each time you run Terraform. Run the following commands, replacing the highlighted values:

```
    export DO_PAT="your_do_api_token"
    export DO_SSH_KEY_NAME="your_ssh_key_name"
```

You can find your API token in your DigitalOcean Control Panel.

Run the plan command with the variable values passed in to see what steps Terraform would take to deploy your project:

```
    terraform plan -var "do_token=${DO_PAT}" -var "ssh_key_name=${DO_SSH_KEY_NAME}"
```

## Infraestructure as code.

IaC, being based on code, should always be coupled with version control software (VCS), such as Git. Storing your infrastructure declarations in VCS makes it easily retrievable, with changes visible to everyone on your team, and provides snapshots at historical points, so you can always roll back to an earlier version if new modifications create errors. Advanced VCS can be configured to automatically trigger the IaC tool to update the infrastructure in the cloud when an approved change is added.

![IaC](./assets/IaC-1.png)

Check the following links to learn more.

## Tutorials.

- https://www.digitalocean.com/community/tutorial_series/how-to-manage-infrastructure-with-terraform
