## Rancher Management Server

### Cloud vendors

- [**Amazon Web Services** (`aws`)](./rancher/aws)
- [**Hetzner Cloud** (`hcloud`)](./rancher/hcloud)


Each vendor module will install Rancher on a single-node K3s cluster, then will provision another single-node RKE2 workload cluster using a Custom cluster in Rancher.
This setup provides easy access to the core Rancher functionality while establishing a foundation that can be easily expanded to a full HA Rancher server.

## Requirements - Cloud

- Terraform >=1.0.0
- Credentials for the cloud provider

### Using cloud modules

To begin with any modules, perform the following steps:

1. Clone or download this repository to a local folder
2. Choose a cloud provider and navigate into the provider's folder
3. Copy or rename `terraform.tfvars.example` to `terraform.tfvars` and fill in all required variables
4. Run `terraform init`
5. Run `terraform apply`

When provisioning has finished, terraform will output the URL to connect to the Rancher server.
Two sets of Kubernetes configurations will also be generated:
- `kube_config_server.yaml` contains credentials to access the cluster supporting the Rancher server
- `kube_config_workload.yaml` contains credentials to access the provisioned workload cluster


### Destroy

Run `terraform destroy -auto-approve` to remove all resources without prompting for confirmation.
