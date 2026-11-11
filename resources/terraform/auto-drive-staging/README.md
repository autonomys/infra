# Auto Drive Staging Environment

Builds the Auto Drive staging environment on the Chronos testnet.

This pass covers the **files gateway host only**, and on it only the Subspace
node, so that its archival Chronos sync can start while the rest is built.

The project provisions boxes that already exist; it creates no cloud resources.
Each host is configured by a role module that takes an IP and an SSH user and is
independent of where the machine comes from. The files gateway host,
`auto-drive-files-gateway-chronos`, uses `modules/auto-drive-gateway-host`.

Every role builds on `modules/host-bootstrap`: hostname, SSH hardening, UFW,
fail2ban, unattended upgrades, the Infisical CLI, and Docker with the loki log
driver via `scripts/installer.sh`.

## The gateway role

`modules/auto-drive-gateway-host` deploys from the compose files in
[autonomys/auto-files-gateway](https://github.com/autonomys/auto-files-gateway),
checked out on the host at the commit pinned in `main.tf`. It does not keep its
own copy. It passes the files in the same order and under the same Compose
project name as that repo's own deploy playbook, so volume names match.

Image references, the chain, the object-mapping start block and the list of
services to start are inputs. Terraform writes them to
`~/deploy/auto-files-gateway.env` and re-runs the deploy whenever any of them,
the pinned commit, or the deploy script changes. An Infisical-fetched
`~/deploy/.env` is also read when present, for the services that need secrets;
the node needs none.

Before starting anything, the deploy resolves the compose model and refuses to
continue if a service would publish a port beyond `127.0.0.1` other than the
node's P2P ports 30333 and 30433. Ports Docker publishes bypass UFW.

The node runs as the gateway repo defines it, with `--chain chronos`,
`--sync full`, `--blocks-pruning archive`, `--state-pruning archive` and
`--create-object-mappings 1`. Its RPC (9944) is published on loopback only.

### Not yet

Defined in the gateway repo but not started by this pass:

- `subspace-rpc-gateway`, `file-retriever`, `object-mapping-app`: they need a
  database, and their compose definitions publish ports beyond loopback, which
  the deploy's port check rejects until that changes upstream
- the DAG indexer (`docker/dag-indexer`)
- metrics agents: the fleet host agent comes later from its own module. Its
  ports 8430, 9100 and 9633 on loopback are left free, and no node_exporter runs
  here
- node Prometheus metrics on 127.0.0.1:9615: upstream's node command does not
  pass `--prometheus-listen-on` and its compose file does not publish 9615

## Building the gateway host from scratch

### 1. Reinstall the OS

This step uses the current provider's rescue system and its `installimage`
installer, so it is the part to replace if the box moves to another supplier.

Activate the rescue system from the provider's control panel (Linux, 64 bit, with
your SSH key), then reboot or reset the box. The activation is valid for **one
boot only** and **expires after 60 minutes** if you don't reboot in that window.

SSH in as root and install:

```bash
curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/auto-drive-staging/installimage-gateway.conf -o /autosetup
installimage
```

`installimage` consumes `/autosetup` and skips its menus. `/`, swap and `/boot`
are all **RAID 1** across both NVMe drives.

> **First build on a new box:** run `installimage` with no `/autosetup` first. The
> editor opens a config already populated for that hardware, which is the only
> reliable source for drive names, the image filename and whether the box needs an
> explicit ESP partition. Copy that config out, fold it into a new
> `installimage-<role>.conf` keeping the `SWRAID`/`SWRAIDLEVEL`/`HOSTNAME` lines,
> and commit.

Reboot into the installed system when it finishes.

### 2. Install legacy-BIOS GRUB on both disks

The provider's Ubuntu image installs the UEFI GRUB package even on BIOS boxes.
Its updates never touch the BIOS boot code, which has left fleet servers
unbootable. As root on the installed system:

```bash
curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/auto-drive-staging/install-bios-grub.sh -o install-bios-grub.sh
bash install-bios-grub.sh
```

It replaces the UEFI package with `grub-pc`, records both disks as its install
devices so later GRUB updates keep both current, runs `grub-install
--target=i386-pc` on each and checks each first sector afterwards. Re-running it
is safe.

### 3. Create the deploy user

Still as root:

```bash
curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/auto-drive-staging/first-boot.sh -o first-boot.sh
bash first-boot.sh
```

It creates the `ubuntu` user with passwordless sudo and the deployer key taken
from root's `authorized_keys`, and nothing more. Root login by key remains until
the bootstrap sets `PermitRootLogin no` during the apply.

### 4. Apply

Prerequisites:

- Terraform Cloud workspace `auto-drive-staging` in the `subspace-sre` org, with
  execution mode set to **local**
- Infisical path `/auto-drive-staging` holding this project's
  `common.auto.tfvars` with `gateway_host_ipv4`. The address lives there rather
  than in the repo, which is public.
- A local `user.auto.tfvars` with your `ssh_agent_identity`
- The deploy key loaded in your SSH agent (`ssh-add -l`)

```bash
./resources/terraform/manage.sh auto-drive-staging init
./resources/terraform/manage.sh auto-drive-staging plan
./resources/terraform/manage.sh auto-drive-staging apply
```

The apply bootstraps the host, then starts the node and fails if it is not
running, or restarts, within 30 seconds of starting.

## Verifying

```bash
./resources/terraform/auto-drive-staging/validate.sh                      # SSH host "auto-drive-files-gateway-chronos"
./resources/terraform/auto-drive-staging/validate.sh ubuntu@<HOST_IPv4>
```

Every check only reads. It covers what `terraform plan` cannot see: RAID 1 on
`/`, swap and `/boot` with both members active and in sync, GRUB boot code on
both disks, SSH hardening, the firewall, that nothing but SSH and node P2P
listens beyond loopback, the host agent's ports left free, and the node's image,
flags, health, peers and log driver. It ends by sampling the node's sync state a
minute apart to show whether it is importing blocks.

The array resyncs for a while after install; until it finishes the sync checks
fail, which is expected. `cat /proc/mdstat` on the host shows progress.

### Confirming the node is syncing

On the host:

```bash
curl -s -H 'Content-Type: application/json' \
  -d '{"id":1,"jsonrpc":"2.0","method":"system_syncState"}' http://127.0.0.1:9944
sudo docker logs --tail 20 \
  $(sudo docker ps -q --filter label=com.docker.compose.service=subspace-node)
```

`currentBlock` should rise between calls.

### Confirming logs reach Loki

The node's container logs ship through the loki driver to
`https://logging.subspace.network/loki/api/v1/push`. Check in Grafana Explore
with:

```
{host="auto-drive-files-gateway-chronos", compose_service="subspace-node"}
```

Push failures show in the Docker daemon's journal as `error sending batch`, which
`validate.sh` checks for.

## Changing what runs

- Image tags, the pinned gateway commit and the service list are in `main.tf`.
  Changing any of them re-runs the deploy on the next apply.
- Services removed from `services` are not stopped; stop their containers by
  hand.
- To re-run the bootstrap without a change, plan with
  `-replace=module.files_gateway.module.host.null_resource.bootstrap`.

## Rules for these hosts

- Treat them as production.
- Keep their addresses out of this repo, PR descriptions and commit messages.
- Bind every container port to `127.0.0.1` unless it must be public. The gateway
  role's deploy enforces this.

## Recovery from total host loss

Repeat "Building the gateway host from scratch", then `validate.sh`. The node
resyncs from genesis.
