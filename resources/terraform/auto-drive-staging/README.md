# Auto Drive Staging Environment

Builds the auto-drive staging host at `staging.auto-drive.autonomys.xyz` from
scratch. A single bare-metal server runs the whole stack, so unlike
`auto-drive-production` this project creates no cloud resources: it provisions a
box that already exists, via `modules/auto-drive-host`.

End state is a host that Docker, nginx and Let's Encrypt are configured on, with
the compose topology in place, ready for the `Deploy Auto Drive Backend` workflow
in the auto-drive repo to land the app on it. This project never starts the app:
the `.env` only exists once that workflow fetches it from Infisical.

Part of [autonomys/infra#556](https://github.com/autonomys/infra/issues/556).

## Deviations from production

Staging is deliberately not a like-for-like copy:

| | Production | Staging |
|---|---|---|
| Postgres | RDS 17.9 | container, same 17.9 and collation, docker volume |
| RabbitMQ | Amazon MQ | container, docker volume |
| Auth | AWS Lambda | `auth` container on the box |
| Host count | 3 EC2 | 1 bare metal |
| Network target | mainnet | mainnet (same, for realism) |

Staging data is disposable by design.

## Naming: the host is not the network

The box is `auto-drive-staging-01`, with no network in the name, while the deploy
group and Infisical path are `auto_drive_mainnet_staging`. That split is deliberate.

The host is a machine; the Infisical path is a set of app configuration (RPC
endpoints, EVM contract address, gateway URLs). Repointing staging at a testnet is
then a matter of deploying a different config set to the same box, not renaming or
rebuilding it. `target_machines` in the deploy workflow selects which set to apply.

Keep the two namespaces separate when adding to either.

## What this manages

### Automated (Terraform)

| Resource | Description |
|---|---|
| `null_resource.setup_auto_drive_host` | Runs `scripts/installer.sh` then `scripts/auto-drive-host-bootstrap.sh` |
| `null_resource.configure_auto_drive_host` | Installs the compose topology and the nginx vhost, sets the hostname |

No cloud resources. The box is a pre-existing bare-metal server.

### Automated (bootstrap script, re-runnable)

`scripts/auto-drive-host-bootstrap.sh` brings the OS up to spec. Both
`null_resource`s are keyed on content hashes, so editing that script, the module's
`docker-compose.yml` or its nginx template re-runs the affected step on the next
apply without a manual taint. Configuration therefore cannot drift.

- SSH hardening (no root login, no password auth, key only)
- UFW: deny incoming, SSH from anywhere, 80/443 from Cloudflare's published ranges
  only; fail2ban sshd jail; unattended upgrades
- nginx, plus the templated vhost for both staging domains and a default server
  that refuses TLS handshakes for any other hostname
- Let's Encrypt certificates via certbot DNS-01, with a renewal hook that reloads nginx
- Infisical CLI, which the deploy playbook shells out to
- `/home/ubuntu/deploy/auto-drive` and the auto-drive checkout under `src/`

Docker, the loki log driver and the journald and kernel tuning come from the shared
`scripts/installer.sh`, which this reuses unchanged.

### Not automated (one-time, per box)

The OS images installed on the box ship root-only with no cloud-init, so these two
cannot be driven from Terraform. Both live in this directory so a rebuild is copy-paste rather than recollection.
`installimage.conf` is the one provider-specific piece: it drives the current
provider's installer. Everything from `first-boot.sh` on assumes only an Ubuntu box
reachable over SSH.

| File | When |
|---|---|
| `installimage.conf` | In the rescue system, as `/autosetup` |
| `first-boot.sh` | As root on the installed system, before the first apply |

## Building the box from scratch

### 1. Reinstall the OS

This step uses the current provider's rescue system and its `installimage`
installer, so it is the part to replace if the box moves to another supplier.

Activate the rescue system from the provider's control panel (Linux, 64 bit, with
your SSH key), then reboot or reset the box. Two constraints: the activation is
valid for **one boot only** and **expires after 60 minutes** if you don't reboot in
that window.

SSH in as root and install. The repo is public, so the config needs no copy/paste:

```bash
curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/auto-drive-staging/installimage.conf -o /autosetup
installimage
```

`installimage` consumes `/autosetup` and skips its menus.

> **First build on a given box:** run `installimage` with no `/autosetup` first. The
> editor opens a config already populated for that hardware, which is the only
> reliable source for drive names, the image filename and whether the box needs an
> explicit ESP partition. Copy that config out, fold it into `installimage.conf`
> keeping the `SWRAID`/`SWRAIDLEVEL`/`HOSTNAME` lines, and commit. Rebuilds are then
> the two commands above.

`/` and swap are striped **RAID 0**: full capacity and throughput, no redundancy.
That's consistent with staging being ephemeral by intent, but it does mean either
drive failing costs the root filesystem. `installimage` keeps the 1 GiB `/boot` on
RAID 1 whatever `SWRAIDLEVEL` says.

### 2. Create the deploy user

Reboot into the installed system, SSH in as root, and:

```bash
curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/auto-drive-staging/first-boot.sh -o first-boot.sh
bash first-boot.sh
```

Deliberately minimal: it creates the `ubuntu` user with sudo and the deployer key,
and nothing more. Everything else belongs in the bootstrap script, which re-runs.

Provided you authenticated to rescue with an SSH key, `installimage` has already
disabled the root password and password-based root SSH, and copied your key to
`/root/.ssh/authorized_keys`, which is where `first-boot.sh` picks it up. Root
login by key remains until the bootstrap sets `PermitRootLogin no` during the apply.

### 3. Apply

Prerequisites for this step:

- Terraform Cloud workspace `auto-drive-staging` in the `subspace-sre` org, with
  execution mode set to **local**
- Infisical path `/auto-drive-staging` holding this project's `common.auto.tfvars`
  (host IPv4, Let's Encrypt contact, auto-drive ref). The IPv4 lives here rather
  than in `main.tf` because it is the origin behind proxied records in a public repo.
- A local `user.auto.tfvars` with your `ssh_agent_identity` and the Cloudflare API
  token certbot uses for DNS-01. As in the other projects, these are personal and
  never stored in Infisical.
- The deploy key loaded in your SSH agent (`ssh-add -l`); the provisioners
  connect through the agent, not an identity file

## Usage

```bash
./resources/terraform/manage.sh auto-drive-staging init
./resources/terraform/manage.sh auto-drive-staging plan
./resources/terraform/manage.sh auto-drive-staging apply
```

Re-applying is safe. Both `null_resource`s are keyed on content hashes, so editing
`scripts/auto-drive-host-bootstrap.sh`, the module's `docker-compose.yml` or its
nginx template re-runs the affected step without a manual taint.

## Verifying the box before DNS is repointed

Run `validate.sh` to check the live host against this spec. It covers what
`terraform plan` cannot see: SSH hardening, the RAID level, firewall rules, the
certificates, the nginx vhost and the deploy layout.

```bash
./validate.sh                          # uses SSH host "auto-drive-staging"
./validate.sh ubuntu@<HOST_IPv4>       # explicit host
```

Its reachability checks curl the vhosts from the box itself, where a **502 from
nginx** is the expected answer before the first deploy: certificates and vhosts work,
no upstream is running yet. Curling the box from your own machine will time out:
that's the firewall doing its job, and `validate.sh` checks that it does.

## Rules for this host

- Point only proxied (orange-cloud) records at it, A or AAAA.
- Keep its addresses out of this repo, PR descriptions and commit messages.
- Bind every container port to `127.0.0.1`: ports Docker publishes bypass UFW.
- Ports 80 and 443 accept Cloudflare's published ranges only. They're fetched when
  the bootstrap runs; to pick up a change Cloudflare announces, re-run it:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan \
  -replace=module.auto_drive_staging.null_resource.setup_auto_drive_host \
  -out=auto-drive-staging.tfplan
./resources/terraform/manage.sh auto-drive-staging apply
```

## Cutover, once the box verifies

1. Repoint DNS. Both records still live in the `dns` project: set
   `staging_autodrive` and `download_staging_autodrive` in `proxied.json` to the
   box's IPv4, then `manage.sh dns apply`. Moving them into this workspace is
   deliberately left as separate work.
2. Populate Infisical `/auto_drive_mainnet_staging` with the app environment.
3. Add the host to the auto-drive repo's `HOSTS_INI_BASE_64` secret under
   `[auto_drive_mainnet_staging]`.
4. Run the `Deploy Auto Drive Backend` workflow with
   `target_machines=auto_drive_mainnet_staging`.

## Recovery from total host loss

Repeat "Building the box from scratch" above: `/autosetup` + `installimage`,
`first-boot.sh`, `manage.sh auto-drive-staging apply`, then the deploy workflow.
Finish with `./validate.sh`. Data is lost, which is the accepted trade-off above.
