# DigitalOcean & Subspace IAC

Everything is a resource. Use Terraform to create and maintain the infrastructure as code.

## Use Terraform.

For all resources, there is a way to define it using Terraform. Check the [Terraform docs](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs) for more information.

- Run **terraform plan** command to check state changes and generate a plan file to be used by **terraform apply**.

- Run **terraform apply** to deploy changes on infrastructure and keep track of it on the Terraform state.

### Current state / environments.

- aries-dev
- aries-test

### Resource Naming.

#### Project (Name: project-name-env)

    - Example: aries-dev
    - Example: aries-test
    - Example: general-resources

#### Droplets (Name: project-name-env-droplet-name-ddmmyyyy)

    - Example: aries-dev-nodes-farmer-relayer-03112021
    - Example: aries-test-nodes-farmer-relayer-03112021

#### Volumes (project-name-env-volume-name-sizegb)

Volumes are global resources, they cannot be attached to a project only, so we need to tag the project name and env in the volume name.

    - Example: aries-dev-relayer-data-250gb
    - Example: aries-test-relayer-data-250gb
