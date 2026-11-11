# Auto Drive Staging Environment

Builds the Auto Drive staging environment on the Chronos testnet.

So far it covers two hosts: the files gateway, running only the Subspace node so
that its archival Chronos sync can start while the rest is built, and the
services host, running Postgres and RabbitMQ for the others.

The project provisions boxes that already exist; it creates no cloud resources.
Each host is configured by a role module that takes an IP and an SSH user and is
independent of where the machine comes from. The files gateway host,
`auto-drive-files-gateway-chronos`, uses `modules/auto-drive-gateway-host`; the
services host, `auto-drive-staging-services`, uses
`modules/auto-drive-services-host`. The hosts reach each other over a private
WireGuard mesh, `modules/wireguard-mesh`.

Every role builds on `modules/host-bootstrap`: hostname, SSH hardening, UFW,
fail2ban, unattended upgrades, and Docker with the loki log driver via
`scripts/installer.sh`. Hosts never fetch secrets themselves: Terraform writes
the ones a role needs, from this project's tfvars.

## The gateway role

`modules/auto-drive-gateway-host` deploys from the compose files in
[autonomys/auto-files-gateway](https://github.com/autonomys/auto-files-gateway),
checked out on the host at the commit pinned in `main.tf`. It does not keep its
own copy. It passes the files in the same order and under the same Compose
project name as that repo's own deploy playbook, so volume names match.

Image references, the chain, the object-mapping start block and the list of
services to start are inputs. Terraform writes them to
`~/deploy/auto-files-gateway.env` and re-runs the deploy whenever any of them,
the pinned commit, or the deploy script changes. A `~/deploy/.env` is also read
when present, for the services that need secrets; the node needs none. Nothing
writes it yet. The gateway repo's own playbook fetches it with the Infisical CLI
on the host, but these hosts never fetch secrets themselves: when a service that
needs them is started here, Terraform will write them from this project's tfvars,
as it does for the services host.

Before starting anything, the deploy resolves the compose model and refuses to
continue if a service would publish a port beyond `127.0.0.1` and the host's
mesh address, other than the node's P2P ports 30333 and 30433. Ports Docker
publishes bypass UFW. Both roles run the same check,
`scripts/compose-port-guard.py`.

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

## The services role

`modules/auto-drive-services-host` runs Postgres 17.9 and RabbitMQ 3.13, the
versions production runs, from a compose file kept in the module. Their data
lives in named volumes, and their logs ship through the loki driver in
non-blocking mode, so an unreachable Loki can't stall either service.

| Service             | Port  | Published on                             |
| ------------------- | ----- | ---------------------------------------- |
| Postgres            | 5432  | loopback and the mesh address 10.77.0.10 |
| RabbitMQ AMQP       | 5672  | loopback and the mesh address            |
| RabbitMQ management | 15672 | loopback only, through an SSH tunnel     |

The other hosts connect over the mesh:

```
postgres://postgres:<postgres_password>@10.77.0.10:5432/<database>
amqp://<rabbitmq_username>:<rabbitmq_password>@10.77.0.10:5672
```

Postgres holds the `postgres` database, which the backend and Hasura share, plus
`gateway`, both under the one `postgres` account. Auth's database is not here:
as in production, it is Aurora DSQL, so its migrations meet DSQL's rules before
they reach production. RabbitMQ has the one account `rabbitmq_username`,
created when the broker first starts; changing the name later needs a fresh
broker volume.

The passwords come from this project's `services.auto.tfvars` in Infisical.
Terraform writes them to owner-only env files in `~/deploy/auto-drive-services/`
and keeps only their hashes in state. Each image applies its password only when
its data is first created, so every deploy sets both again from the containers'
own environment, and a password changed in tfvars takes effect on the next apply.

The deploy runs the same published-port check as the gateway, refuses to start
if the mesh address isn't on the host, and fails the apply unless both services
turn healthy within 300 seconds and stay healthy, without restarting, for 30
seconds more.

### Sizing

For a 64 GB box, set in `main.tf`:

| Setting                    | Value  | Why                                                        |
| -------------------------- | ------ | ---------------------------------------------------------- |
| Postgres memory limit      | 32 GiB | half the box; Postgres's file cache counts against it too  |
| `shared_buffers`           | 8GB    | a quarter of Postgres's limit                              |
| `effective_cache_size`     | 24GB   | shared buffers plus the file cache that fits in its limit  |
| `work_mem`                 | 32MB   | per sort or hash, so modest with up to 300 connections     |
| `maintenance_work_mem`     | 1GB    | faster vacuum and index builds                             |
| `max_connections`          | 300    | the backend's pools, Hasura and the gateway together       |
| `max_wal_size`             | 4GB    | fewer forced checkpoints in write bursts                   |
| `random_page_cost`         | 1.1    | NVMe: random reads cost little more than sequential ones   |
| `effective_io_concurrency` | 200    | NVMe serves many reads at once                             |
| Postgres `shm_size`        | 2 GiB  | Docker's 64 MB default is too small for parallel queries   |
| RabbitMQ memory limit      | 4 GiB  | the broker is told it, as it doesn't read the container's limit, and raises its memory alarm at 40% of it |

## The private mesh

The staging hosts talk to each other over WireGuard rather than a provider's
private network, so the mesh moves with them to any supplier. Every host peers
directly with every other; nothing is routed through a third host.

| Member          | Host                               | Mesh address |
| --------------- | ---------------------------------- | ------------ |
| `services`      | `auto-drive-staging-services`      | 10.77.0.10   |
| `files-gateway` | `auto-drive-files-gateway-chronos` | 10.77.0.20   |

The subnet is `10.77.0.0/24`, with a block of ten addresses per role, and the
port is 51820/udp. Members and their addresses are in `local.mesh_hosts` in
`main.tf`. Each member's public endpoint is its host address variable, and its
public key is in `mesh_public_keys`, both in this project's
`common.auto.tfvars` in Infisical.

What each host gets, from `modules/wireguard-mesh`:

- `wg0`, run by `wg-quick@wg0`. Its private key is generated on the host on the
  first apply, in `/etc/wireguard/wg0.key` (root, 0600), and never leaves it.
  Terraform renders `wg0.conf` without it and the host adds it when installing
  `/etc/wireguard/wg0.conf` (root, 0600), so the key appears in neither
  Terraform variables nor state, and `wg-quick`'s own commands, including
  `systemctl reload wg-quick@wg0`, keep it.
- UDP 51820 open in UFW to the other members' endpoints only, as `mesh-peer`
  rules the mesh keeps itself, so a member joining, leaving or moving changes
  only the mesh, not every host's bootstrap.
- Docker ordered after `wg-quick@wg0` at boot, so containers that publish on the
  mesh address find it there.
- `net.ipv4.ip_nonlocal_bind = 1`, so if `wg0` is not up those containers still
  start, on loopback at once and on the mesh as soon as `wg0` is. Without it they
  fail to start, loopback ports included, and Docker never retries them. The
  mesh address only accepts traffic while it is on `wg0`.
- A `DOCKER-USER` rule, added while `wg0` is up, that drops connections to the
  host's mesh address arriving on any interface but `wg0`. Docker-published
  ports bypass UFW, and without it a machine on the same provider network could
  reach them by routing to the mesh address.

Services meant for other members publish on the host's mesh address, never on
`0.0.0.0`. A container reaching a service on its own host uses the Compose
network, not the mesh address.

Peer changes are applied in place without dropping traffic. Changing a host's
own mesh address or the port restarts its `wg0`, which interrupts the mesh for a
few seconds while the other members handshake again.

### Adding a host to the mesh

1. Build the host and add its role module to `main.tf` with a `mesh` input,
   its entry in `local.mesh_hosts`, and its address variable in
   `common.auto.tfvars`.
2. Apply. The new host generates its key and brings up `wg0` with the other
   members as peers, and the others open the mesh port to it. The apply output
   ends with the new host's public key:

   ```
   ==> This host's mesh public key: <KEY>
   ```

   It can also be read later with `ssh ubuntu@<HOST_IPv4> sudo wg show wg0 public-key`.
3. Add the key to `mesh_public_keys` in `common.auto.tfvars`, run
   `manage.sh auto-drive-staging store-secrets`, then plan and apply again. Every
   other member adds the new host as a peer.
4. Add the member and its address to `validate.sh`, and run it on each host.

A rebuilt host has a new key, so after rebuilding one, repeat step 3 with its new
key. Moving a host to another provider is the same: update its address variable,
apply, then update its key.

### Taking a host out of the mesh

1. Remove its entry from `local.mesh_hosts` and `mesh_public_keys` and its
   role's `mesh` input (the gateway role takes `mesh = null`), then plan and
   apply. The other members drop it as a peer and close the mesh port to it.
2. Terraform does nothing on the departing host itself, so tidy it by hand.
   Stopping `wg0` also removes its `DOCKER-USER` rule:

   ```bash
   sudo systemctl disable --now wg-quick@wg0
   sudo rm -f /etc/wireguard/wg0.conf /etc/wireguard/wg0.key /etc/systemd/system/docker.service.d/10-wireguard-mesh.conf /etc/sysctl.d/90-wireguard-mesh.conf
   sudo systemctl daemon-reload
   sudo sysctl -w net.ipv4.ip_nonlocal_bind=0
   sudo ufw status | grep '# mesh-peer'
   ```

   Then delete each `mesh-peer` rule listed with
   `sudo ufw delete allow proto udp from <PEER_IPv4> to any port 51820`.

## Building a host from scratch

The steps are the same for every role; only the install config differs.

### 1. Reinstall the OS

This step uses the current provider's rescue system and its `installimage`
installer, so it is the part to replace if the box moves to another supplier.

Activate the rescue system from the provider's control panel (Linux, 64 bit, with
your SSH key), then reboot or reset the box. The activation is valid for **one
boot only** and **expires after 60 minutes** if you don't reboot in that window.

SSH in as root and install, with `ROLE` set to `gateway` or `services`:

```bash
ROLE=gateway
curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/auto-drive-staging/installimage-$ROLE.conf -o /autosetup
installimage
```

`installimage` consumes `/autosetup` and skips its menus. `/`, swap and `/boot`
are all **RAID 1** across both NVMe drives.

> **First build on a new box:** run `installimage` with no `/autosetup` first. The
> editor opens a config already populated for that hardware, which is the only
> reliable source for drive names, the image filename and whether the box needs an
> explicit ESP partition. Copy that config out, fold it into a new
> `installimage-<role>.conf` keeping the `SWRAID`/`SWRAIDLEVEL`/`HOSTNAME` lines,
> and commit. `installimage-services.conf` is the gateway's with the hostname
> changed, since the boxes match.

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
  `common.auto.tfvars`, with `gateway_host_ipv4`, `services_host_ipv4` and
  `mesh_public_keys`, and `services.auto.tfvars`, with `postgres_password`,
  `rabbitmq_username` and `rabbitmq_password`. The addresses live there rather
  than in the repo, which is public. Each password must be at least 32 letters
  and digits, such as the output of `openssl rand -hex 24`.
- A local `user.auto.tfvars` with your `ssh_agent_identity`
- The deploy key loaded in your SSH agent (`ssh-add -l`)

```bash
./resources/terraform/manage.sh auto-drive-staging init
./resources/terraform/manage.sh auto-drive-staging plan
./resources/terraform/manage.sh auto-drive-staging apply
```

The apply bootstraps each host, brings up its mesh interface, then deploys its
role: on the gateway the node, which fails the apply if it is not running, or
restarts, within 30 seconds of starting; on the services host Postgres and
RabbitMQ, as in "The services role". After the first apply on a rebuilt host,
record its new mesh public key (see "Adding a host to the mesh").

## Verifying

```bash
./resources/terraform/auto-drive-staging/validate.sh files-gateway                      # SSH host "auto-drive-files-gateway-chronos"
./resources/terraform/auto-drive-staging/validate.sh services                           # SSH host "auto-drive-staging-services"
./resources/terraform/auto-drive-staging/validate.sh files-gateway ubuntu@<HOST_IPv4>
```

Every check only reads, and none reads a private key or a password. It covers
what `terraform plan` cannot see: RAID 1 on `/`, swap and `/boot` with both
members active and in sync, GRUB boot code on both disks, SSH hardening, the
firewall, that nothing but the role's ports listens beyond loopback and the mesh
address, the host agent's ports left free, and the mesh: `wg0`'s address and
port, that it has its key loaded, the key and config files' permissions, that
the peers are exactly the other members and each answers a ping over the mesh,
that UFW opens the mesh port to peers only, Docker's ordering after `wg0`, and
the `DOCKER-USER` rule.

On the gateway it then checks the node's image, flags, health, peers and log
driver, and samples its sync state a minute apart to show whether it is
importing blocks. On the services host it checks that Postgres and RabbitMQ are
healthy, their images, limits, volumes, log driver and listeners, that the
databases exist and the Postgres tuning took effect, that RabbitMQ sized itself
to its limit, and that it has no `guest` user.

It also reports whether `wg0` came up before Docker on the current boot. That
only holds once the host has rebooted since it joined the mesh.

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

The containers' logs ship through the loki driver to
`https://logging.subspace.network/loki/api/v1/push`. Check in Grafana Explore
with:

```
{host="auto-drive-files-gateway-chronos", compose_service="subspace-node"}
{host="auto-drive-staging-services", compose_project="auto-drive-services"}
```

Push failures show in the Docker daemon's journal as `error sending batch`, which
`validate.sh` checks for.

## Changing what runs

- Image tags, the pinned gateway commit, the gateway's service list and the
  services host's sizing are in `main.tf`. Changing any of them re-runs that
  host's deploy on the next apply.
- Services removed from the gateway's `services` are not stopped; stop their
  containers by hand.
- A new Postgres or RabbitMQ major version needs its data migrated first; a
  minor or patch release only needs the tag changed.
- A password changed in `services.auto.tfvars` takes effect on the next apply;
  restart whatever uses it after updating its settings.
- To re-run a bootstrap without a change, plan with
  `-replace=module.<files_gateway or services>.module.host.null_resource.bootstrap`.
  The host's mesh and deploy re-run with it.

## Rules for these hosts

- Treat them as production.
- Keep their addresses out of this repo, PR descriptions and commit messages.
- Bind every container port to `127.0.0.1`, or to the host's mesh address if
  other members need it, unless it must be public. Both roles' deploys enforce
  this.

## Recovery from total host loss

Repeat "Building a host from scratch" up to the apply. A host rebuilt at the same
address changes none of Terraform's triggers, so a plain plan finds nothing to
do. Plan its first apply with its bootstrap replaced instead; its mesh and
deploy follow the bootstrap. For the services host:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -replace=module.services.module.host.null_resource.bootstrap
```

For the gateway:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -replace=module.files_gateway.module.host.null_resource.bootstrap
```

Then `manage.sh auto-drive-staging apply`, record the host's new mesh public key
(see "Adding a host to the mesh"), and run `validate.sh`. The gateway's node
resyncs from genesis. The services host has no backups: rebuilding it starts
with empty databases and queues.
