# DigitalOcean & Subspace IAC

In DigitalOcean everything is a resource.

- Volumes
- Droplets
- Backups...

In this context, we use Terraform to create and maintain the infrastructure as code.

## Use Terraform.

Remember, this allow us to get several benefits among order, basic security, monitoring, automation, etc.

- For all resources, there is a way to define it using terraform.
- Always run **terraform plan** command to check state changes.
- Always run **terraform apply** from main branch.
  - This contains the current infrastructure state and must be done after team discussion and PR approval.

Check the [terraform docs](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs) for more information.

### Current state / environments.

- aries-dev
- aries-test

### Resource Naming.

This is a set of conventions about defining and creating DigitalOcean resources with Terraform.  
The idea is to have a clear way to identify resource by environment and purposes.

We describe the one we use for now:

#### Project (Name: project-name-env)

    - Example: aries-dev
    - Example: aries-test
    - Example: general-resources

#### Droplets (Name: project-name-env-droplet-name-ddmmyyyy)

    - Example: aries-dev-nodes-farmer-relayer-03112021
    - Example: aries-test-nodes-farmer-relayer-03112021

#### Volumes (project-name-env-volume-name-sizegb)

Volumes are global resources and they cannot be attached to a project only, so we need to tag the project name and env in the volume name itself.

    - Example: aries-dev-relayer-data-250gb
    - Example: aries-tes-relayer-data-250gb

_If you are using a resouce that is not described here, please add it here, so we can have a clear and consistent naming._

### Other Settings.

_Feel free to add other missing or new resources definitions_
