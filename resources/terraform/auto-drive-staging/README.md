# Auto Drive Staging Environment

Builds the Auto Drive staging environment on the Chronos testnet.

So far it covers three hosts: the files gateway, running only the Subspace node
so that its archival Chronos sync can start while the rest is built; the services
host, running Postgres and RabbitMQ for the others; and the public backend,
running Hasura and the download API and worker behind nginx.

The project provisions boxes that already exist; it creates no cloud resources.
Each host is configured by a role module that takes an IP and an SSH user and is
independent of where the machine comes from. The files gateway host,
`auto-drive-files-gateway-chronos`, uses `modules/auto-drive-gateway-host`; the
services host, `auto-drive-staging-services`, uses
`modules/auto-drive-services-host`; the public backend,
`auto-drive-staging-public`, uses `modules/auto-drive-backend-host`, which the
private backend will reuse with different inputs. The hosts reach each other
over a private WireGuard mesh, `modules/wireguard-mesh`.

Every role builds on `modules/host-bootstrap`: hostname, SSH hardening, UFW,
fail2ban, unattended upgrades, and Docker with the loki log driver via
`scripts/installer.sh`. Hosts never fetch secrets themselves: Terraform writes
the ones a role needs, from this project's tfvars.

## The gateway role

`modules/auto-drive-gateway-host` deploys from its own compose files, in its
`compose/` directory. `compose/docker-compose.yml` defines the services as the
compose files of
[autonomys/auto-files-gateway](https://github.com/autonomys/auto-files-gateway)
do at the commit named in its header, with the same variable names, so the two
can be compared side by side. `upstream-diff.sh` in the module shows what has
changed there since, so the file can be brought up to date and the commit
moved:

```bash
./modules/auto-drive-gateway-host/upstream-diff.sh
```

Terraform writes the values to a `.env` beside the files, each in single quotes
so Compose takes it literally: the node image, the chain, the object-mapping
setting, the node's log level and the Loki URL. The `.env` also names the
Compose project, `file-retriever`, and the files to use.
`compose/docker-compose.log-cap.yml` caps the loki driver's local copy of the
logs as on the rest of the fleet, and is included unless the module's
`cap_local_logs` is off. Every file in `compose/` and the `.env` land in
`~/deploy/auto-drive-gateway/`, so on the host

```bash
cd ~/deploy/auto-drive-gateway && docker compose ps
```

sees what the deploy sees. The deploy re-runs whenever a file or a value
changes. The project name is the one the gateway repo's own deploy playbook ends
up with, so a host deployed by that playbook keeps its volumes, the node's chain
data among them.

Before starting anything, the deploy resolves the compose model and refuses to
continue if a service would publish a port beyond `127.0.0.1` and the host's
mesh address, other than the node's P2P ports 30333 and 30433. Ports Docker
publishes bypass UFW. Both roles run the same check,
`scripts/compose-port-guard.py`.

The node runs with `--chain chronos`, `--sync full`, `--blocks-pruning archive`,
`--state-pruning archive` and `--create-object-mappings yes`. Its RPC (9944) is
published on loopback only. With `yes` the node creates mappings for blocks as
it archives them and carries on where archiving left off when it restarts, so a
restart takes minutes. A block number there would instead re-archive the chain
from that block on every start before importing anything, which takes hours at
Chronos' height. Any change to the node's definition or image restarts it on the
next apply.

A host still deployed from the gateway repo's own files can move to this role
without restarting its node, as long as the role resolves the node exactly as
that host runs it. Compare before its first apply: the node container's
`com.docker.compose.config-hash` label against
`docker compose config --hash subspace-node`, run over this module's compose
files and a `.env` holding that host's values. Any difference restarts the node
on the first apply.

Hosts deployed before the role had its own compose file still have the gateway
repo's checkout in `~/deploy/auto-files-gateway`, with
`~/deploy/auto-files-gateway.env` and `~/deploy/auto-files-gateway.override.yml`.
Nothing reads them any more; they can be removed by hand.

### Not yet

Defined in the gateway repo but not in the role's compose file yet:

- `subspace-rpc-gateway`, `file-retriever`, `object-mapping-app`: they need the
  services host's database and secrets from this project's tfvars
- the DAG indexer (`docker/dag-indexer`)
- metrics agents: the fleet host agent comes later from its own module. Its
  ports 8430, 9100 and 9633 on loopback are left free, and no node_exporter runs
  here
- node Prometheus metrics on 127.0.0.1:9615: adding `--prometheus-listen-on`
  changes the node's command, so it waits for the node's next planned restart

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

## The public backend role

`modules/auto-drive-backend-host` runs Auto Drive's backend the way production's
backend hosts do. Its `compose/docker-compose.yml` mirrors
`docker-compose.prod.yml` in
[autonomys/auto-drive](https://github.com/autonomys/auto-drive) at the commit
named in its `# upstream:` line, with the same services, profiles and variable
names, and lists where it differs: ports published on one address rather than
every interface, Hasura's assets from the backend image (below), and no broker or
New Relic agent. Terraform writes the `.env` beside it, each value in single
quotes so Compose takes it literally, which fills in the compose file and, as on
production's hosts, is the backend services' environment. Everything that differs between staging and production, or between
the public and private hosts, is an input: images, profiles, ports and the
address they are published on, the database and broker URLs, the endpoints the
backend calls, settings, hostnames and the log target.
`compose/docker-compose.log-cap.yml` caps the log driver's local copies, as on
the gateway. Every file in `compose/` and the `.env` land in
`~/deploy/auto-drive/`, so `docker compose` run there sees what the deploy does.

`upstream-diff.sh` in the module shows what has changed upstream since the
mirrored commit, in the compose file, the nginx configs, the playbook that
deploys them, and what decides the backend image's settings, layout and
migrations.

The public host runs what production's public host runs, at the versions
production ran when this was built, so upgrades can be rehearsed here first:

| Service                   | Image                                | Port | Published on |
| ------------------------- | ------------------------------------ | ---- | ------------ |
| `hasura`                  | `hasura/graphql-engine:v2.40.0.cli-migrations-v3` | 6565 | loopback |
| `backend-download-api`    | `ghcr.io/autonomys/auto-drive-backend:99e753be` | 3000 | loopback |
| `backend-download-worker` | the same                             | 3030 | loopback |

Both images are pinned by digest as well. The profiles are production's
public host's `COMPOSE_PROFILES`, `base,download`. Production's New Relic agent
is left out; the fleet's host agent comes separately.

### Migrations and Hasura's assets

Before any service starts on a new backend image, the deploy runs the backend's
database migrations from that image (`yarn workspace backend db-migrate up`),
with credentials staged for that run only and never written to the services'
`.env`. Only the host with `run_migrations` does this. db-migrate applies only
what the database lacks.

Hasura's metadata and SQL migrations also come from the backend image: a
one-shot `hasura-assets` service copies `apps/hasura` from it into a volume
before Hasura starts, so they always match the backend's schema. Hasura applies
them when it starts, as production's does today. `hasura.apply_sql_migrations =
false` copies the metadata only, which is the change in autonomys/auto-drive#946.

### nginx and certificates

Host nginx serves the site, with `nginx.conf` and the server blocks after
production's `nginx/nginx.conf` and `nginx/backend.mainnet.public.conf`:

| Name                                      | Cloudflare  | Serves                                           |
| ----------------------------------------- | ----------- | ------------------------------------------------ |
| `public.staging.auto-drive.autonomys.xyz` | proxied     | `/api`, `/hasura`, `/s3`, `/file`, `/folder`     |
| `s3.staging.auto-drive.autonomys.xyz`     | not proxied | the S3 API at its root                           |
| `gateway.staging.autonomys.xyz`           | proxied     | the same routes as the app name (below)          |

The gateway alias is a CNAME to the app name, as production's
`gateway.autonomys.xyz` is. Cloudflare's Full mode reaches the origin over
HTTPS, and with no 443 server of its own the alias lands on the app's, the first
on 443, so it answers every app route. Its port-80 server block, `/file` and
`/folder` only, is reached only if Cloudflare connects over plain HTTP.

UFW opens 80 and 443 to everyone, as production's security group does, since the
S3 name is reached directly. Let's Encrypt issues one certificate for the first
two names through certbot's nginx authenticator, under `admin@autonomys.xyz`;
certbot's timer renews it and reloads nginx. Before the certificate exists the
deploy serves only the port-80 blocks certbot validates through, so the names
must resolve to the host before its first full apply. Set
`ingress.letsencrypt.staging = true` to try issuance against Let's Encrypt's
staging CA, which has far looser rate limits; setting it back issues a trusted
certificate.

As in production, nginx trusts no forwarded client address, so its rate limits
key on Cloudflare's edge addresses for the proxied names.
`ingress.real_ip_from` takes Cloudflare's ranges to change that.

The S3 name isn't proxied, so its record publishes the host's address, which
the proxied app name shares. `/api` and `/hasura`, the console included, can
therefore also be reached at that address directly, without Cloudflare. That
reaches nothing Cloudflare doesn't already serve: the console needs the admin
secret either way, and nginx's rate limits apply on both paths. Only
Cloudflare's own protection is bypassed. Production avoids it by giving S3 its
own address, which only the S3 server block listens on; a host with one address
can't, and staging accepts the exposure.

### Settings and secrets

`main.tf` sets production's public backend settings with Chronos and staging
values in place of mainnet's: the Chronos consensus and Auto EVM RPCs, the
staging auth name, and `METRIC_ENVIRONMENT_TAG = staging`. The files gateway's
file retriever and object-mapping indexer are reached over the mesh, at the
gateway host's mesh address, where production uses their public names. Staging's Postgres has no TLS, so `ACCEPT_UNAUTHORIZED_CERTS`, which
production sets for RDS, is left out.

The database and broker URLs are built from `services.auto.tfvars` and the
services host's mesh address. The files gateway's token is
`files_gateway_token` from `gateway.auto.tfvars`, the same value the gateway's
file retriever checks. The rest comes from `backend.auto.tfvars`. All of
it reaches the host only in the owner-only `~/deploy/auto-drive/.env`, and only
its hash reaches the state. As on production, every backend service reads the
whole `.env`, Hasura's admin secret included.

### Deploy checks

The deploy checks the uploaded files before they replace the ones in use, as the
gateway's does. It refuses to continue if a service would publish a port beyond
loopback, or if the database or broker can't be reached, and fails the apply
unless every service turns healthy within 300 seconds and stays healthy, without
restarting, for 30 seconds more, and `/api/health` and `/hasura/healthz` answer
through nginx. A configuration nginx rejects is put back to the previous one
before anything reloads. The migrations and the deploy wait for the services
host's deploy in the same apply, since it sets the passwords they connect with.

## The private mesh

The staging hosts talk to each other over WireGuard rather than a provider's
private network, so the mesh moves with them to any supplier. Every host peers
directly with every other; nothing is routed through a third host.

| Member          | Host                               | Mesh address |
| --------------- | ---------------------------------- | ------------ |
| `services`      | `auto-drive-staging-services`      | 10.77.0.10   |
| `files-gateway` | `auto-drive-files-gateway-chronos` | 10.77.0.20   |
| `public`        | `auto-drive-staging-public`        | 10.77.0.30   |

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

SSH in as root and install, with `ROLE` set to `gateway`, `services` or `public`:

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
  `common.auto.tfvars`, with `gateway_host_ipv4`, `services_host_ipv4`,
  `public_host_ipv4` and `mesh_public_keys`, and `services.auto.tfvars`, with
  `postgres_password`, `rabbitmq_username` and `rabbitmq_password`. The
  addresses live there rather than in the repo, which is public. Each password
  must be at least 32 letters and digits, such as the output of
  `openssl rand -hex 24`.
- `gateway.auto.tfvars` in the same path, with `files_gateway_token` (from
  `openssl rand -hex 32`): the file retriever's API secret, which the backends
  present as their bearer token
- For the backend hosts, `backend.auto.tfvars` in the same path, with
  `hasura_admin_secret` and `auth_service_api_key` (each from
  `openssl rand -hex 32`), `hasura_jwt_public_key`, the VictoriaMetrics
  `victoria_username` and `victoria_password`, and optionally
  `slack_webhook_url`. `hasura_jwt_public_key` is the public half of the RS256
  pair auth signs its tokens with:

  ```bash
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out auth-jwt.key
  openssl pkey -in auth-jwt.key -pubout
  ```

  The private half becomes auth's `JWT_SECRET`, base64-encoded, when auth is
  deployed. Keep it in Infisical, not on disk.
- The public host's names in DNS, pointing at it, before its first full apply
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
RabbitMQ, as in "The services role"; on the public backend the migrations, then
nginx, its certificate and the services, as in "The public backend role". After
the first apply on a rebuilt host, record its new mesh public key (see "Adding a
host to the mesh").

A new backend host can't reach the services host until its key is recorded, so
its first apply stops at the mesh:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -target=module.public.module.mesh
```

Then record the key, plan and apply in full.

## Verifying

```bash
./resources/terraform/auto-drive-staging/validate.sh files-gateway                      # SSH host "auto-drive-files-gateway-chronos"
./resources/terraform/auto-drive-staging/validate.sh services                           # SSH host "auto-drive-staging-services"
./resources/terraform/auto-drive-staging/validate.sh public                             # SSH host "auto-drive-staging-public"
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

On the gateway it then checks that the running node matches the compose files,
the node's image, flags, health, peers and log driver, and samples its sync state a minute apart to show whether it is
importing blocks. On the services host it checks that Postgres and RabbitMQ are
healthy, their images, limits, volumes, log driver and listeners, that the
databases exist and the Postgres tuning took effect, that RabbitMQ sized itself
to its limit, and that it has no `guest` user. On the public backend it checks
that the migrations ran with the deployed image and Hasura's assets came from it,
each service's health, image, restart policy, log driver and loopback listener,
the file cache volume, that Hasura's metadata is consistent, that Postgres and
RabbitMQ are reachable over the mesh from the host and from a container, nginx,
the certificate's names, issuer, expiry and renewal, and that the site answers
through nginx and redirects HTTP to HTTPS.

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
{host="auto-drive-staging-public", compose_project="auto-drive"}
```

Push failures show in the Docker daemon's journal as `error sending batch`, which
`validate.sh` checks for.

## Changing what runs

- Image tags, the gateway node's settings and the services host's sizing are in
  `main.tf`. Changing any of them re-runs that host's deploy on the next apply.
- A change to the gateway node's settings or image restarts the node on that
  apply.
- A new Postgres or RabbitMQ major version needs its data migrated first; a
  minor or patch release only needs the tag changed.
- A password changed in `services.auto.tfvars` takes effect on the next apply;
  restart whatever uses it after updating its settings.
- To re-run a bootstrap without a change, plan with
  `-replace=module.<files_gateway, services or public>.module.host.null_resource.bootstrap`.
  The host's mesh and deploy re-run with it.
- To move the backend to a new image, first list what changed upstream since
  the commit the compose file mirrors, and bring the compose file and the
  module's nginx templates up to date with it:

  ```bash
  ./modules/auto-drive-backend-host/upstream-diff.sh <new commit>
  ```

  Then move the `# upstream:` line, and the backend image's tag (the same
  commit's first eight characters) and digest in `main.tf`, together. The apply
  runs the new migrations, re-copies Hasura's assets, and recreates the
  services.
- Changing the public host's names needs a new certificate: delete the old one
  with `sudo certbot delete --cert-name <old app name>` on the host, then apply.

## Rules for these hosts

- Treat them as production.
- Keep their addresses out of this repo, PR descriptions and commit messages.
- Bind every container port to `127.0.0.1`, or to the host's mesh address if
  other members need it, unless it must be public. Every role's deploy enforces
  this.

## Recovery from total host loss

Repeat "Building a host from scratch" up to the apply. A host rebuilt at the same
address changes none of Terraform's triggers, so a plain plan finds nothing to
do: plan its first apply with its bootstrap replaced instead, and its mesh and
deploy follow the bootstrap.

A rebuilt host also has a new mesh key, which the other members don't have until
it is recorded. A host whose deploy reaches another over the mesh, or that the
others reach, is therefore rebuilt in two applies: first the host on its own,
then, once its new key is recorded (see "Adding a host to the mesh"), a plan and
apply in full.

For the services host, the first apply:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -replace=module.services.module.host.null_resource.bootstrap -target=module.services
```

The services host has no backups, so it starts with empty databases and queues.
In the full apply after its key is recorded, the other members take the new key,
the public backend's migrations run again, and Hasura and the backend services
are recreated, so the schema and Hasura's metadata are set up again.

For the public backend, the first apply:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -replace=module.public.module.host.null_resource.bootstrap -target=module.public.module.mesh
```

The full apply after its key is recorded runs its migrations, which find the
database already current, and its deploy, which requests a new certificate;
Let's Encrypt issues at most five for the same names a week.

The gateway's deploy reaches nothing over the mesh, so it is rebuilt in one
apply, and its key recorded and applied afterwards. Its node resyncs from
genesis:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -replace=module.files_gateway.module.host.null_resource.bootstrap
```

Apply each plan with `manage.sh auto-drive-staging apply`, and once every key is
recorded and applied, run `validate.sh` on each host.
