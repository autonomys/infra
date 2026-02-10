# Autonomys Network Infrastructure

Terraform IaC for **Autonomys Network** blockchain infrastructure. Manages multiple environments (mainnet, chronos testnet, devnet) across AWS and Cloudflare.

All infrastructure — **projects**, **instances**, **volumes**, **DNS records** — must be defined in this repository, reviewed via PR, and deployed using IaC.

## Prerequisites

- [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Docker](https://docs.docker.com/get-docker/) (for secrets management via Infisical)
- Bash 4+
- AWS credentials
- Infisical credentials (environment variables):
  - `INFISICAL_CLIENT_ID`
  - `INFISICAL_CLIENT_SECRET`
  - `INFISICAL_INFRA_PROJECT_ID`

## Repository Layout

```
modules/                        # Reusable Terraform modules
resources/terraform/            # Individual Terraform projects
templates/                      # Shared script templates
logging/                        # Logging configuration (Grafana Loki, Traefik, VictoriaMetrics)
_docs/                          # Documentation
```

### Modules (`modules/`)

| Module | Description |
|--------|-------------|
| **network-primitives** | Core blockchain node infrastructure (consensus, domain, farmer nodes, VPC, security groups, DNS, load balancers) |
| **chain-indexer** | Blockchain indexing with PostgreSQL + Docker + Traefik |
| **chain-alerts** | Chain monitoring and alerting with Slack integration |
| **operator-reward-distributor** | Automated reward distribution |
| **node-utils** | Docker image with Rust CLI tools for Infisical secret management |

### Projects (`resources/terraform/`)

**Network:**
- `mainnet-consensus` — Mainnet consensus nodes
- `mainnet-domains` — Mainnet domain nodes
- `mainnet-foundation` — Foundation nodes
- `chronos` — Chronos testnet
- `devnet` — Development network

**Services:**
- `mainnet-chain-indexer`, `chronos-chain-indexer` — Blockchain indexers
- `mainnet-chain-alerter`, `chronos-chain-alerter` — Monitoring and alerts
- `mainnet-reward-distributor`, `chronos-reward-distributor` — Reward distribution

**Other:**
- `dns` — Standalone DNS records (autonomys.xyz, autonomys.net, autonomys.network, subspace.network, subspace.net, subspace.foundation, continuum.co, ai3.storage)
- `telemetry` — Telemetry API infrastructure
- `packer` — AMI building
- `auto-drive` — Auto-drive gateway infrastructure
- `auto-kol-memory` — KOL memory infrastructure

Each project follows this structure:

```
<project>/
├── main.tf                      # Module calls
├── backend.tf                   # Terraform Cloud backend (org: subspace-sre)
├── variables.tf                 # Input variables
├── outputs.tf                   # Outputs
├── providers.tf                 # Provider configuration
├── common.auto.tfvars           # Shared secrets (gitignored, stored in Infisical)
├── common.auto.tfvars.example   # Example tfvars template
├── user.auto.tfvars             # User-specific variables (gitignored)
└── config.toml                  # Node keys/secrets (gitignored, stored in Infisical)
```

## Getting Started

### 1. Set AWS credentials

```sh
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
```

### 2. Use the management script

All project management goes through `resources/terraform/manage.sh`:

```sh
# Usage: ./resources/terraform/manage.sh <project> <action>

./manage.sh <project> fetch-secrets   # Fetch secrets from Infisical
./manage.sh <project> init            # Initialize Terraform (also fetches secrets)
./manage.sh <project> upgrade         # Upgrade providers (also fetches secrets)
./manage.sh <project> plan            # Generate plan file at <project>/<project>.tfplan
./manage.sh <project> apply           # Apply plan (also stores secrets back)
./manage.sh <project> destroy         # Destroy resources
./manage.sh <project> output          # Show Terraform outputs
./manage.sh <project> store-secrets   # Store secrets to Infisical
```

### 3. Direct Terraform commands (alternative)

From `resources/terraform/`:

```sh
terraform -chdir=<project> init
terraform -chdir=<project> plan -out=<project>.tfplan
terraform -chdir=<project> apply <project>.tfplan
```

## Secrets Management

Secrets are managed through [Infisical](https://infisical.com/) via a Docker container (`ghcr.io/autonomys/infra/node-utils`).

**Never commit** `.tfvars`, `config.toml`, or `proxied.json` files — they are gitignored and stored in Infisical.

## Providers

| Provider | Version | Purpose |
|----------|---------|---------|
| AWS | 6.17.0 | EC2, VPC, EBS, security groups, load balancers |
| Cloudflare | 5.8.2 | DNS records across 8 domains |

## Backend

All projects use [Terraform Cloud](https://app.terraform.io/) (org: `subspace-sre`) with **local execution mode** — state is stored remotely, execution runs locally.

When creating a new workspace, change the execution mode from remote to local in the workspace settings (Settings > Execution Mode).

## Workflow

1. Create a branch from `main`
2. Make infrastructure changes
3. Run `./manage.sh <project> plan` locally to verify
4. Open a Pull Request to `main` for review
5. After approval, apply changes with `./manage.sh <project> apply`

## Deployment

- Docker containers on EC2 instances, provisioned via `null_resource` with `remote-exec`
- Some nodes run on bare metal (Hetzner) with fixed IPs
- Infrastructure-linked DNS is handled by the `network-primitives` module; standalone DNS records are managed in the `dns` project
