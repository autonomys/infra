# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform IaC for **Autonomys Network** blockchain infrastructure. Manages multiple environments (mainnet, chronos testnet, devnet) across AWS and Cloudflare.

## Common Commands

All project management goes through `resources/terraform/manage.sh` (requires Bash 4+):

```bash
# Usage: ./resources/terraform/manage.sh <project> <action>
# Requires env vars: INFISICAL_CLIENT_ID, INFISICAL_CLIENT_SECRET, INFISICAL_INFRA_PROJECT_ID

./resources/terraform/manage.sh <project> fetch-secrets   # Fetch secrets from Infisical before working
./resources/terraform/manage.sh <project> init            # Initialize terraform (also fetches secrets)
./resources/terraform/manage.sh <project> upgrade         # Upgrade providers (also fetches secrets)
./resources/terraform/manage.sh <project> plan            # Generate plan file at <project>/<project>.tfplan
./resources/terraform/manage.sh <project> apply           # Apply plan (also stores secrets back)
./resources/terraform/manage.sh <project> destroy         # Destroy resources
./resources/terraform/manage.sh <project> output          # Show terraform outputs
./resources/terraform/manage.sh <project> store-secrets   # Store secrets to Infisical
```

Direct terraform commands from `resources/terraform/`:
```bash
terraform -chdir=resources/terraform/<project> init
terraform -chdir=resources/terraform/<project> plan -out=<project>.tfplan
terraform -chdir=resources/terraform/<project> apply <project>.tfplan
```

## Architecture

### Repository Layout
- `modules/` — Reusable Terraform modules
- `resources/terraform/` — Individual Terraform projects
- `templates/` — Shared script templates

### Modules (in `modules/`)
- **network-primitives** — Core module for blockchain node infrastructure (consensus nodes, domain nodes, farmer nodes, VPC, security groups, DNS, load balancers)
- **chain-indexer** — Blockchain indexing with PostgreSQL + Docker + Traefik
- **chain-alerts** — Chain monitoring and alerting
- **operator-reward-distributor** — Automated reward distribution
- **node-utils** — Docker image with Rust CLI tools for secret management

### Projects (in `resources/terraform/`)

**Network projects**: `mainnet-consensus`, `mainnet-domains`, `mainnet-foundation`, `chronos`, `devnet`
**Service projects**: `mainnet-chain-alerter`, `mainnet-chain-indexer`, `mainnet-reward-distributor`, `chronos-chain-alerter`, `chronos-chain-indexer`, `chronos-reward-distributor`
**Other**: `dns`, `telemetry`, `packer`, `auto-drive`, `auto-kol-memory`

Each project follows this structure:
```
<project>/
├── main.tf                    # Module calls
├── backend.tf                 # Terraform Cloud backend (org: subspace-sre)
├── variables.tf               # Input variables
├── outputs.tf                 # Outputs
├── common.auto.tfvars         # Shared secrets (gitignored, stored in Infisical)
├── common.auto.tfvars.example # Example tfvars
├── user.auto.tfvars           # User-specific variables (gitignored, created locally)
├── config.toml                # Node keys/secrets (gitignored, stored in Infisical)
└── providers.tf               # Provider configuration
```

### Providers
- **AWS** (6.17.0) — EC2, VPC, EBS, security groups, load balancers
- **Cloudflare** (5.8.2) — DNS records across 8 domains (autonomys.xyz, autonomys.net, autonomys.network, subspace.network, subspace.net, subspace.foundation, continuum.co, ai3.storage)

### Backend
All projects use Terraform Cloud (org: `subspace-sre`) with local execution mode — state stored remotely, execution runs locally.

## Key Conventions

- **Secrets management**: Infisical via Docker (`ghcr.io/autonomys/infra/node-utils`). Never commit `.tfvars`, `config.toml`, or `proxied.json`.
- **Variable naming**: kebab-case for complex object variables (e.g., `consensus-rpc-node-config`), snake_case for simple variables (e.g., `aws_access_key`).
- **Deployment**: Docker containers on EC2 instances, provisioned via `null_resource` with `remote-exec`. Some nodes run on bare metal (Hetzner) with fixed IPs.
- **DNS**: The `dns/` project manages standalone DNS records. Infrastructure-linked DNS is handled by `network-primitives` module.
- **Workflow**: All changes via PR to main branch. Plan locally, get review, then apply.
- **New workspace setup**: Change execution mode from remote to local in Terraform Cloud workspace settings.
