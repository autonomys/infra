# Auto Drive Staging Environment

Builds the Auto Drive staging environment on the Chronos testnet.

It covers four hosts: the files gateway, running the Subspace node and the
gateway's apps; the services host, running Postgres and RabbitMQ for the others;
the public backend, running Hasura and the download API and worker behind
nginx; and the private backend, running Hasura, the API, the worker and the
publish worker behind nginx, with the auth service beside them.

The project provisions boxes that already exist; it creates no cloud resources.
Each host is configured by a role module that takes an IP and an SSH user and is
independent of where the machine comes from. The files gateway host,
`auto-drive-files-gateway-chronos`, uses `modules/auto-drive-gateway-host`; the
services host, `auto-drive-staging-services`, uses
`modules/auto-drive-services-host`; the public backend,
`auto-drive-staging-public`, and the private backend,
`auto-drive-staging-private`, both use `modules/auto-drive-backend-host` with
different inputs. Auth runs on the private backend host from
`modules/auto-drive-auth`. The files gateway and the public backend also each
run a Chronos farmer, with a pruned node of its own, from
`modules/subspace-farmer`. The hosts reach each other over a private WireGuard
mesh, `modules/wireguard-mesh`.

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

It runs the Subspace node, the RPC gateway, the object-mapping indexer
(`object-mapping-app`), the file retriever and, given `dag_indexer`, the DAG
indexer and the `gateway` database's backups. Each app's database migrations
run in a one-shot service before the app starts, on every deploy; a run with
nothing new to apply changes nothing. The deploy runs them before it installs
anything, so a migration that fails leaves the running apps as they were.

Terraform writes the settings to a `.env` beside the files, each in single
quotes so Compose takes it literally: the images, the chain, the object-mapping
setting, the log levels, the apps' settings and the Loki URL. The `.env` also
names the Compose project, `file-retriever`, and the files to use. The secrets go
in `object-mapping-indexer.env`, `file-retriever.env` and `gateway-db.env`
instead, readable by the deploy user only: the database's credentials, from
`postgres_password` in `services.auto.tfvars`, and the file retriever's API
secret, `files_gateway_token` in `gateway.auto.tfvars`.
`compose/docker-compose.mesh.yml` publishes the indexer and the file retriever on
the host's mesh address as well as loopback, for the backends.
`compose/docker-compose.log-cap.yml` caps the loki driver's local copy of the
logs as on the rest of the fleet, and is included unless the module's
`cap_local_logs` is off. `compose/docker-compose.dag-indexer.yml` and its two
scripts are included given `dag_indexer`. The files in `compose/` and the env
files land in `~/deploy/auto-drive-gateway/`, so on the host

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

### The apps

- The RPC gateway reaches the node over the compose network and publishes its
  RPC (9955) on loopback only. Upstream also publishes 30334 and 30434 for it,
  but it listens on neither, so they are left out.
- The object-mapping indexer (3000) and the file retriever (8090) listen on
  loopback and the mesh address. Both use the services host's `gateway`
  database, as `postgres`, over the mesh.
- The backends reach them at `http://10.77.0.20:8090` with
  `files_gateway_token` as their bearer token (`FILES_GATEWAY_URL`,
  `FILES_GATEWAY_TOKEN`), and at `ws://10.77.0.20:3000/ws`
  (`OBJECT_MAPPING_ARCHIVER_URL`).
  The gateway module outputs both URLs, as `file_retriever_url` and
  `object_mapping_url`. Its deploy waits for the services host's deploy, which
  sets the database password the migrations connect with. When the services host
  is rebuilt (`database_id`), the migrations run again and both apps are
  recreated, since each keeps the one database connection it opens.
- The indexer stores the mappings the node sends while it is subscribed. With
  `--create-object-mappings yes` that is every block archived from then on;
  earlier blocks would need one run with a block number.
- File retriever metrics stay off unless the module is given `metrics`.

### The DAG indexer

The DAG indexer is the SubQuery node that fills the `dag-indexer` schema in the
services host's `gateway` database. The file retriever looks every download up
in that schema, so without it every download fails. It runs with the flags the
gateway repo's own compose file gives it, `/ready` as its health check, and its
API on `127.0.0.1:30001` only.

The image, `dag_indexer.image`, is the gateway repo's DAG indexer image: the
SubQuery node with the mapping, `schema.graphql` and one manifest per network in
`/app`, each starting at block 1. The indexer runs `/app/project.<network>.yaml`
for the role's `network_id`, with the node's RPC on the compose network as its
endpoint. Before anything changes, the deploy reads the image and refuses it
unless:

- its manifest for the network exists, and starts at the block the index
  recorded on its first start. The indexer refuses a start block above its
  progress and ignores a lower one.
- its `schema.graphql` is the one the schema was created from, whose hash the
  deploy records as the schema's comment. On a database without the schema,
  the deploy creates it with the hash before the indexer starts, and the
  indexer creates its tables in it. The indexer never alters an existing
  schema's tables: a new field makes it stop at its first write. Bring the
  tables up to date by hand first, then set `dag_indexer.accept_schema_sha256`
  to the new file's hash for one apply. A schema with no hash recorded is
  refused the same way, as which file built its tables is unknown.

A new image recreates the indexer, and the index resumes where it left off.
`validate.sh` checks that the running bundle, `/app/dist/index.js`, is the
pinned mapping. The index follows the chain's finalized head, which on Chronos
trails the best block by five segments, about six days.

On an empty or missing schema the indexer starts over from its start block,
which takes a day or two on Chronos. So `dag-indexer-start-guard.js` runs before
it and compares the database's progress with the floor the last backup recorded
(see "Backups of the gateway database"). If the database is behind, the guard
exits with `refusing to start`, and Docker retries until the database is
restored or a deploy with `database_start_empty` removes the floor. The deploy
makes the same check, on both indexes, before it runs the migrations.

### Backups of the gateway database

With `dag_indexer`, the gateway host also backs up the services host's `gateway`
database, which holds both indexes, over the mesh. `gateway-db-backup` runs
`gateway-db.sh backup` in `dag_indexer.backup_image` on every deploy, which
fails if its backup does, and nightly from the `auto-drive-gateway-db-backup`
systemd timer.

- Each dump is a `pg_dump -Fc` in `/var/backups/auto-drive-gateway`, readable by
  root only, beside a `.progress` file: the DAG index's `lastProcessedHeight`
  and the highest block in `object_mappings`, read just before the dump, so the
  dump holds at least that much.
- Both only ever rise. A dump behind the last good one's progress is kept as
  `.dump.suspect`, the run fails, and it doesn't count towards the seven dumps
  kept, so a run of bad dumps can't push out the last good one. Only the two
  newest suspect dumps are kept.
- The last good dump's progress is the floor, in `floor/progress-floor`, named
  after that dump. The deploy and the start guard refuse a database behind it.
  Two settings let one apply past it, and do nothing once the database has
  caught up; take them out after that apply:
  - `database_start_empty = "<floor>"`, with the floor's name from the deploy's
    refusal, such as `gateway-20261116T023000Z`, removes that floor, so the
    indexes carry on from whatever the database holds: an older dump restored on
    purpose resumes from there, and an empty database starts over. Any later
    floor has another name, so a value left set doesn't remove it;
  - `dag_indexer.accept_rewind_to = <height>`, after rewinding the DAG index by
    hand, lowers the floor's DAG height to that height.
- Auto Drive's own database, on the same Postgres, isn't backed up.

### Restoring the gateway database

A rebuilt services host starts with an empty `gateway` database. Restore it
before the gateway's deploy runs against it:

1. Before rebuilding, stop the apps that use the database, on the gateway host.
   A stopped container stays stopped, across reboots too, and the start guard
   is there if this step is missed:

   ```bash
   cd ~/deploy/auto-drive-gateway && docker compose stop dag-indexer object-mapping-app file-retriever
   ```

2. Rebuild the services host with its first apply, and record its new mesh key,
   as in "Recovery from total host loss".
3. Apply the other members' meshes only, so the gateway reaches the new host:

   ```bash
   terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
     -target=module.files_gateway.module.mesh -target=module.public.module.mesh
   ```

4. Restore the newest dump, on the gateway host. It refuses a database that
   already holds either index:

   ```bash
   sudo ls /var/backups/auto-drive-gateway
   cd ~/deploy/auto-drive-gateway && sudo docker compose run --rm --no-deps -T gateway-db-backup restore gateway-<newest>.dump
   ```

   It runs as one transaction, so nothing is visible until it finishes, and a
   failed restore leaves the database empty to try again.

5. To restore an older dump instead, such as when the newest is damaged, name
   it in the same command. The database is then behind the floor on both
   indexes, which `dag_indexer.accept_rewind_to` can't pass, as it only lowers
   the DAG height. For the next apply, set `database_start_empty` to the
   floor's name, which the deploy's refusal gives: it removes the floor, and
   the indexes resume from that dump.
6. Plan and apply in full. The deploy finds the database at the floor, or past
   it with `database_start_empty`, the migrations find their records, the apps
   start again, and the index resumes where the dump left it. Take
   `database_start_empty` out after that apply.
7. Mappings the node archived while the indexer app was stopped are lost.
   `validate.sh` counts indexed DAG nodes without a mapping once the index has
   passed their blocks, which on Chronos is up to six days later. A gap needs
   the mapping backfill in "Recovery from total host loss".

### Not yet

Defined in the gateway repo but not in the role's compose file yet:

- metrics agents: the fleet's host agent covers this host from its own module,
  which validates it too
- node Prometheus metrics on 127.0.0.1:9615: adding `--prometheus-listen-on`
  changes the node's command, so it waits for the node's next planned restart

## The services role

`modules/auto-drive-services-host` runs Postgres 17.9 and RabbitMQ 3.13, the
versions production runs, from its own compose file,
`compose/docker-compose.yml`. Terraform writes the values to a `.env` beside it,
each in single quotes so Compose takes it literally: the images, the mesh
address, the memory limits, Postgres's `shm_size` and settings, and the Loki
URL. The `.env` also names the Compose project, `auto-drive-services`, and the
file to use. Terraform also writes `rabbitmq.conf`, which tells the broker its
memory limit. All of them land in `~/deploy/auto-drive-services/`, so on the
host

```bash
cd ~/deploy/auto-drive-services && docker compose ps
```

sees what the deploy sees. Their data lives in named volumes, and their logs
ship through the loki driver in non-blocking mode, so an unreachable Loki can't
stall either service.

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
`gateway` and `auth`, all under the one `postgres` account. Production's auth
database is Aurora DSQL; staging's starts here and moves later, so until then
auth's migrations do not meet DSQL's rules before they reach production.
RabbitMQ has the one account `rabbitmq_username`,
created when the broker first starts; changing the name later needs a fresh
broker volume.

The passwords come from this project's `services.auto.tfvars` in Infisical.
Terraform writes them to owner-only env files beside the compose file,
`postgres.env` and `rabbitmq.env`, never to the `.env`, and keeps only their
hashes in state. Each image applies its password only when its data is first
created, so every deploy sets both again from the containers' own environment,
and a password changed in tfvars takes effect on the next apply.

The deploy checks the uploaded files before they replace the ones in use: it
runs the same published-port check as the gateway and refuses to continue if
the mesh address isn't on the host. It then fails the apply unless both
services turn healthy within 300 seconds and stay healthy, without restarting,
for 30 seconds more.

### Sizing

Each Postgres setting is a variable in `compose/docker-compose.yml`, and the
module accepts exactly those. A new setting goes into the compose file and the
module's check on `postgres.settings` before `main.tf` can set it.

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
whole `.env`, Hasura's admin secret included. What only the workers may hold
goes in `worker_secrets` instead (see "The private backend").

### Deploy checks

The deploy checks the uploaded files before they replace the ones in use, as the
gateway's does. It refuses to continue if a service would publish a port beyond
loopback, or if the database or broker can't be reached, and fails the apply
unless every service turns healthy within 300 seconds and stays healthy, without
restarting, for 30 seconds more, and `/api/health` and `/hasura/healthz` answer
through nginx. A configuration nginx rejects is put back to the previous one
before anything reloads. The migrations and the deploy wait for the services
host's deploy in the same apply, since it sets the passwords they connect with.

## The private backend

The same role with production's private host's profiles, `base,frontend`, and
the same images as the public host:

| Service                  | Command                | Port | Published on |
| ------------------------ | ---------------------- | ---- | ------------ |
| `hasura`                 | as on the public host  | 6565 | loopback     |
| `backend-api`            | `start:fe:api`         | 3000 | loopback     |
| `backend-worker`         | `start:fe:worker`      | 3030 | loopback     |
| `backend-publish-worker` | `start:publish:worker` | 3031 | loopback     |

Only the public host runs the migrations. This host's deploy waits for the
public host's, so its Hasura starts on a database the other has already brought
up to the image's metadata and migrations.

`ALL_SERVICES_ACTIVE` is on here and off on the public host. It turns on the
task manager and the object-mapping listener in the worker, and it is what lets
the publish worker sign. The host's other settings are production's private
host's: the confirmation depth, the log level, the broker prefetch, the
attribution start and the API description URL, under this host's name. Payments
stay off (`BUY_CREDITS_ACTIVE` unset, the contract address zero) until there is
a credits contract on Chronos' Auto EVM; production runs them, so its payment
settings are left out too.

### The publish worker

`backend-publish-worker` is the only on-chain publisher. Its signing accounts'
nonces are tracked in one process, so two publishers collide. Exactly one runs:

- only this host has the `frontend` profile, and the project refuses a plan in
  which the number of backend hosts running the publish worker is not one;
- its host port is fixed, so a second replica of the service can't start;
- `validate.sh` checks for one container here and, from the services host, for
  exactly one consumer on the `publish-manager` queue.

It signs with the accounts in `publish_private_keys`, in `private.auto.tfvars`:
their secret URIs, comma-separated. They are staging-only accounts funded on
Chronos, never one that exists on mainnet. Production keeps its seeds out of
the API's environment by resolving them from a secret store in the worker
processes only. Here they go in `worker_secrets`, which Terraform writes to an
owner-only `~/deploy/auto-drive/workers.env`, and
`compose/docker-compose.workers-env.yml` gives that file to `backend-worker`
and `backend-publish-worker` alone. The API, which takes requests from the
internet, never holds them.

### nginx, certificate and firewall

The site is after production's `nginx/backend.mainnet.private.conf`:

| Name                                    | Cloudflare | Serves                          |
| --------------------------------------- | ---------- | ------------------------------- |
| `chronos.auto-drive.autonomys.xyz`      | proxied    | `/api`, `/hasura`               |
| `auth.staging.auto-drive.autonomys.xyz` | proxied    | auth, except onboarding (below) |

One Let's Encrypt certificate covers both names. Both are proxied, so UFW opens
80 and 443 to Cloudflare's ranges only (`ingress.allow_from`, from
`local.cloudflare_ipv4` in `main.tf`), where production and the public host
open them to everyone. The origin can't be reached around Cloudflare. Let's
Encrypt's check arrives through Cloudflare too.

## Auth

Production runs auth as a Lambda behind an API gateway. Here it is a container
on the private backend host, from `modules/auto-drive-auth`, which takes a host
another role has bootstrapped. Its `compose/docker-compose.yml` has two
services: `auth-migrate`, a one-shot that applies auth's database migrations,
and `auth`. Terraform writes the image, the port, the Loki URL and auth's
settings to a `.env` beside it, and the three credentials to an owner-only
`auth.env`: the database URL, built from `postgres_password`; the signing key,
`auth_jwt_private_key` in `auth.auto.tfvars`; and the API secret, which is the
backends' `auth_service_api_key`. They land in `~/deploy/auto-drive-auth/`.

Auth is published on loopback, on 3040 since 3030 is the backend worker's here,
and the private host's nginx serves it under its own name. The backends reach
it at that name, as production's reach the API gateway.

Before it changes anything, the deploy checks the uploaded files: the published
port, that the database is reachable, and that the signing key is the private
half of `hasura_jwt_public_key`, since a mismatched pair starts cleanly and
then has every token refused. It runs the migrations next, so a migration that
fails leaves the running auth as it was, then starts auth and fails the apply
unless it turns healthy within 300 seconds and, for 30 more, keeps answering
its health route without restarting.

Auth needs no sign-in provider's credentials: for Google, Discord and GitHub it
takes the provider's own token from the caller and asks the provider whose it
is. Those providers' client IDs and secrets belong to a frontend.

### Who can use staging

Onboarding is for staff. Auth onboards anyone who presents a valid provider
token, and onboarding is what gives a user an organization, API keys and an
upload allowance. So nginx refuses the onboarding route
(`public_onboarding = false`), and it answers only on auth's own port, which
needs SSH access to the host:

```bash
ssh -L 3040:127.0.0.1:3040 auto-drive-staging-private
curl -X POST http://127.0.0.1:3040/users/@me/onboard \
  -H "Authorization: Bearer <a GitHub token of yours>" -H "X-Auth-Provider: github"
```

That is all the rule keeps to staff. Anyone with a provider account can still
sign in: auth gives an account that is not onboarded a session. It has no
organization, so it gets no API key and no upload allowance.

Everything else is served at the auth name, so an onboarded user creates API
keys and signs in as on production. The route that makes a user an admin needs
an existing admin, so the first is made by setting that user's `role` to
`Admin` in the `auth` database's `users.users` table.

`STAFF_DOMAINS` does not restrict any of this: it only says who counts as staff
for a feature flag in staff-only mode.

## The farmers

The files gateway and the public backend each run a Chronos farmer with a 1 GiB
farm, through a pruned node of its own, from `modules/subspace-farmer`. Like
auth, the role takes a host another role has bootstrapped. Its
`compose/docker-compose.yml` has two services, `node` and `farmer`. Terraform
writes the images, the chain, the sync mode, the ports, the farm size, the
reward address, the host's address and the Loki URL to a `.env` beside it, and
both land in `~/deploy/subspace-farmer/`. The node's chain data and the farm are
in the project's named volumes, `subspace-farmer_node-data` and
`subspace-farmer_farm`. The gateway's own node, in the `file-retriever` project,
is a separate archive node that the farmer doesn't use.

Their rewards go to `suexrxoBh96UgcCyKXVMTEUhR8LtJozJssVT8Wrzs16bjBSn6`, the
staging-only account the private backend's publish worker signs with, so farming
funds publishing. The address is public, so it is in `main.tf` and `validate.sh`.
If `publish_private_keys` moves to another account, move it too.

| Port  | Listener   | Default | Published on    |
| ----- | ---------- | ------- | --------------- |
| 30343 | node P2P   | 30333   | every interface |
| 30443 | node DSN   | 30433   | every interface |
| 30543 | farmer DSN | 30533   | every interface |

Each is its default plus ten, the same on both hosts and clear of the gateway's
node, and each is TCP, as every listener the node and the farmer have is. Each is
published as itself, and the farmer is told the host's address with
`--external-address`, which Docker's NAT would otherwise hide from it, so it
serves the DSN as a Kademlia server from the start. The node's RPC stays on 9944
inside its container, unpublished. The farmer reaches it over the project's
network, so the node serves it beyond its own loopback with `--rpc-cors all` and
`--rpc-methods unsafe`: under the defaults the farmer's WebSocket is refused,
and so are its slot, signing and piece calls.

The deploy keeps the three ports open in UFW under a comment of its own,
`farmer-port`, which host-bootstrap's firewall pass leaves alone, as it leaves
the mesh's `mesh-peer` rules. So adding, moving or removing the farmers touches
neither host's bootstrap. Docker-published ports bypass UFW anyway: before it
installs anything, the deploy runs `scripts/compose-port-guard.py` on its compose
model with those three as the only public ports. It then starts the node, and the
farmer once the node is healthy, and fails the apply unless both are running
within 300 seconds and neither restarts in the 30 seconds after. A failure
prints both containers' restart counts and the Loki query for their errors:
the loki driver's local copy, which `docker logs` reads, holds only a
container's current run, so the error a restarted container exited with is
only in Loki.

### Sync

Both nodes full-sync, which takes about two days to reach Chronos' tip, and a
farmer wins nothing until its node is synced. Snap sync, the node's default,
failed in every attempt when this was built, tried with the
`chronos-2026-aug-18` release. It needs reachable farmers to serve the chain's segment headers and
found too few, so the node exited with `Snap sync exited with a fatal error ...
Can't find peers to download headers from`, and again after every restart. Snap
sync applies only to an empty database: to try it again, set `local.farmer.sync`
to `snap` before a host's node starts from empty.

### Farm size

The farmer refuses less than about 1021 MiB, one sector and its overhead, so
`1GiB` is the smallest. A 1 GiB farm holds one sector and takes 1.07 GB on disk.
Changing `local.farmer.farm_size` recreates the farmer only. It extends the farm
in place and plots the new sectors at the lowest thread priority, behind
everything else on the host. 10 GiB holds about ten sectors.

### Moving or retiring the farmers

Everything the role puts on a host is its own: `~/deploy/subspace-farmer/`, the
compose project and its volumes, and the `farmer-port` rules. To move the
farmers to another Terraform project, deploy the same module there with the same
compose project. Then remove both blocks from `main.tf` and the farmer checks and
ports from `validate.sh`, and apply here. That only drops their deploys from this
state, so they keep running, and the other project's first deploy keeps their
chain data and farms.

To retire them, remove the blocks and apply, then on each host:

```bash
cd ~/deploy/subspace-farmer && docker compose down -v && cd
rm -rf ~/deploy/subspace-farmer
for port in 30343 30443 30543; do sudo ufw delete allow "$port/tcp"; done
```

## The private mesh

The staging hosts talk to each other over WireGuard rather than a provider's
private network, so the mesh moves with them to any supplier. Every host peers
directly with every other; nothing is routed through a third host.

| Member          | Host                               | Mesh address |
| --------------- | ---------------------------------- | ------------ |
| `services`      | `auto-drive-staging-services`      | 10.77.0.10   |
| `files-gateway` | `auto-drive-files-gateway-chronos` | 10.77.0.20   |
| `public`        | `auto-drive-staging-public`        | 10.77.0.30   |
| `private`       | `auto-drive-staging-private`       | 10.77.0.40   |

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
   A host whose deploy reaches another member over the mesh, as the gateway's
   and the public backend's reach the services host's Postgres, would fail its
   deploy here: plan this apply with `-target=module.<its module>.module.mesh`,
   and its deploy runs in step 3.
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

SSH in as root and install, with `ROLE` set to `gateway`, `services`, `public`
or `private`:

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
  `public_host_ipv4`, `private_host_ipv4` and `mesh_public_keys`, and
  `services.auto.tfvars`, with
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

  The private half is `auth_jwt_private_key` in `auth.auto.tfvars`, in the same
  path. Keep it in Infisical, not on disk.
- For the private backend, `private.auto.tfvars` in the same path, with
  `publish_private_keys`: the secret URIs of the staging-only accounts the
  publish worker signs with, funded on Chronos
- Each backend host's names in DNS, pointing at it, before its first full apply
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
nginx, its certificate and the services, as in "The public backend role"; on
the private backend the same without the migrations, then auth; and on the
gateway and the public backend, the farmer and its node. After the first
apply on a rebuilt host, record its new mesh public key (see "Adding a host to
the mesh").

A new backend host can't reach the services host until its key is recorded, so
its first apply stops at the mesh:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -target=module.public.module.mesh
```

Then record the key, plan and apply in full. The private backend is the same,
with `-target=module.private.module.mesh`; auth deploys with it in the full
apply.

The gateway's deploy runs its apps' migrations against the services host's
Postgres over the mesh too, so a new gateway's first apply stops at its mesh the
same way, with `-target=module.files_gateway.module.mesh`. On a first build of
every host, the first apply covers the services host and the other meshes:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -target=module.services -target=module.public.module.mesh -target=module.private.module.mesh \
  -target=module.files_gateway.module.mesh
```

then record every key (see "Adding a host to the mesh") and plan and apply in
full.

## Verifying

```bash
./resources/terraform/auto-drive-staging/validate.sh files-gateway                      # SSH host "auto-drive-files-gateway-chronos"
./resources/terraform/auto-drive-staging/validate.sh services                           # SSH host "auto-drive-staging-services"
./resources/terraform/auto-drive-staging/validate.sh public                             # SSH host "auto-drive-staging-public"
./resources/terraform/auto-drive-staging/validate.sh private                            # SSH host "auto-drive-staging-private"
./resources/terraform/auto-drive-staging/validate.sh files-gateway ubuntu@<HOST_IPv4>
```

Every check only reads, and none prints a private key or a password. The
services and backend hosts' compose hash checks have Compose read their env
files, to hash them as the deploy does. It covers
what `terraform plan` cannot see: RAID 1 on `/`, swap and `/boot` with both
members active and in sync, GRUB boot code on both disks, SSH hardening, the
firewall, that nothing but the role's ports listens beyond loopback and the mesh
address, and the mesh: `wg0`'s address and
port, that it has its key loaded, the key and config files' permissions, that
the peers are exactly the other members and each answers a ping over the mesh,
that UFW opens the mesh port to peers only, Docker's ordering after `wg0`, and
the `DOCKER-USER` rule.

On the gateway it then checks that the running node matches the compose files,
the node's image, flags, health, peers and log driver, that the apps run their
pinned images, that their migrations finished cleanly, that their logs are capped,
their listeners and their health endpoints, and samples the node's sync state a
minute apart to show whether it is importing blocks. For the DAG indexer it
checks the container, its image, manifest, endpoint, flags, health and listener,
that its bundle is the pinned mapping and its manifest Chronos' from block 1,
its connection to the chain and how far its target trails the best block, that
the index started at block 1, records the image's `schema.graphql`, and is
advancing or caught up, and that every DAG node indexed after Chronos' launch
seeding has its object mapping. The seeding, which ends at block 29,505, wrote
each node into its remark as hex text, and the node maps the text, so none of
its nodes can have a mapping and the gateway can't serve them.
For the backups it checks the timer, the directories' modes, that one to seven
dumps are kept, the newest under 26 hours old and readable, that none was set
aside, that the floor is the newest dump's progress, and that the database is at
or above it. Its database checks run `gateway-db.sh`'s read-only commands in a
one-off container. On the services host it checks that Postgres and RabbitMQ
match the compose files and are healthy, their images, limits, stop timeouts,
volumes, log driver and listeners, that the databases exist and the Postgres
tuning took effect, that RabbitMQ sized itself to its limit, and that it has no
`guest` user. From there it also checks that
the gateway's migrations are recorded, that the DAG indexer's schema exists,
that the indexer and the file retriever answer over the mesh, that auth's
migrations are recorded, and that the publish queue has exactly one consumer.
On a backend host it checks that the migrations ran with the deployed image
(public only) and Hasura's assets came from it, each service's health, image,
restart policy, log driver and loopback listener, the file cache volume, that
Hasura's metadata is consistent, that Postgres and RabbitMQ are reachable over
the mesh from the host and from a container, nginx, the certificate's names,
issuer, expiry and renewal, and that the site answers through nginx and
redirects HTTP to HTTPS. On the private backend it also checks
that 80 and 443 are open to exactly the ingress ranges, that those are the
ranges Cloudflare publishes today, that one publish worker runs, that the
workers hold the signing seeds and the API does not (by name
only), and auth: its files, its migrations, its health, image, log driver and
loopback listener, that it answers through nginx, and that nginx refuses
onboarding.

On the gateway and the public backend it also checks the farmer:

- **Files and model.** Its files, and that the node and the farmer match the
  compose file, run their pinned images, restart unless stopped and log through
  the loki driver, capped.
- **Node.** Its chain, farmer mode, sync mode, listen ports, health and peers.
- **Farmer.** Its farm, reward address and listen port, and that the address it
  advertises is one of the host's own, reported as yes or no, never the address.
- **The farm's own record.** Its allocated space and genesis.
- **Ports and disk.** The three ports published on every interface and open in
  UFW as `farmer-port`, and at least 50 GB free.

It reports the rewards signed since the farmer last started, and samples the
node's sync state a minute apart. It fails if the node or the farmer restarted
between the samples, and says where in Loki their errors are.

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

### Confirming a farmer's node is syncing

On the gateway or the public backend:

```bash
cd ~/deploy/subspace-farmer
docker compose exec node curl -s -H 'Content-Type: application/json' \
  -d '{"id":1,"jsonrpc":"2.0","method":"system_syncState"}' http://localhost:9944
docker compose logs --tail 20 node farmer
```

### Confirming logs reach Loki

The containers' logs ship through the loki driver to
`https://logging.subspace.network/loki/api/v1/push`. Check in Grafana Explore
with:

```
{host="auto-drive-files-gateway-chronos", compose_service="subspace-node"}
{host="auto-drive-staging-services", compose_project="auto-drive-services"}
{host="auto-drive-staging-public", compose_project="auto-drive"}
{host="auto-drive-staging-private", compose_project="auto-drive"}
{host="auto-drive-staging-private", compose_project="auto-drive-auth"}
{host=~"auto-drive-files-gateway-chronos|auto-drive-staging-public", compose_project="subspace-farmer"}
```

Push failures show in the Docker daemon's journal as `error sending batch`, which
`validate.sh` checks for.

## Changing what runs

- Image tags, the gateway's settings and the services host's sizing are in
  `main.tf`. Changing any of them re-runs that host's deploy on the next apply.
- The object-mapping indexer and file retriever images are tagged with the
  auto-files-gateway commit they were built from. Move them together with the
  `# upstream:` commit in the role's compose file, after reading what
  `upstream-diff.sh` shows for that commit.
- A change to the gateway node's settings or image restarts the node on that
  apply. A change to the services host's images, sizing or Postgres settings
  recreates the service it belongs to on that apply.
- The DAG indexer's image is tagged with the auto-files-gateway commit it was
  built from; the index resumes on a new one. Move `DAG_DIST_SHA256` in
  `validate.sh` with it when its mapping changes. The deploy refuses an image
  whose manifest starts at another block, or whose `schema.graphql` differs,
  until the schema is brought up to date.
- A new Postgres or RabbitMQ major version needs its data migrated first; a
  minor or patch release only needs the tag changed.
- A password changed in `services.auto.tfvars` takes effect on the next apply.
  The gateway's apps are recreated with the new database URL in the same apply;
  restart anything else that uses it after updating its settings.
- To re-run a bootstrap without a change, plan with
  `-replace=module.<files_gateway, services, public or private>.module.host.null_resource.bootstrap`.
  The host's mesh and deploy re-run with it, and auth's with the private host's.
- To move the backend to a new image, first list what changed upstream since
  the commit the compose file mirrors, and bring the compose file and the
  module's nginx templates up to date with it:

  ```bash
  ./modules/auto-drive-backend-host/upstream-diff.sh <new commit>
  ```

  Then move the `# upstream:` line, and the backend image's tag (the same
  commit's first eight characters) and digest in `main.tf`, together. The apply
  runs the new migrations, re-copies Hasura's assets, and recreates the
  services, on the public host first and then on the private one.
- The auth image is built from the same repository and tagged with its commit.
  Changing it in `main.tf` runs auth's new migrations and recreates auth.
- To change the publish worker's accounts, change `publish_private_keys` in
  `private.auto.tfvars` and apply: the two workers are recreated and the API is
  not.
- Cloudflare publishes its ranges at https://www.cloudflare.com/ips-v4, and
  `validate.sh private` fails when they differ from its copy. When they change,
  update `local.cloudflare_ipv4` in `main.tf` and `PRIVATE_INGRESS_RANGES` in
  `validate.sh` together; the apply re-runs the private host's bootstrap, and
  with it its mesh and deploys.
- Changing a backend host's names needs a new certificate: delete the old one
  with `sudo certbot delete --cert-name <old app name>` on the host, then apply.
- The farmers' images, sync mode, farm size, reward address and ports are in
  `local.farmer` in `main.tf`, which both hosts share. A new release moves both
  images together, to the newest of the `mainnet-` and `chronos-` tags: mainnet
  releases run Chronos too. A change to the node's image or settings recreates the node, and the
  farmer with it. The farm size and the reward address recreate only the farmer.
  The ports recreate both and swap the UFW rules.

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
apply in full. Every host here is rebuilt that way.

For the services host, the first apply:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -replace=module.services.module.host.null_resource.bootstrap -target=module.services
```

The services host keeps no backups of its own, so it starts with empty databases
and queues. The gateway host keeps the `gateway` database's: restore it as in
"Restoring the gateway database", which also covers stopping the gateway's apps
before the rebuild. In the full apply after its key is recorded, the other
members take the new key. The `database_id` of every app with a database there
follows that key too. The public backend's migrations run again, and Hasura and
the backend services are recreated, so the schema and Hasura's metadata are set
up again. The gateway's apps' migrations run again too, and the apps and the
DAG indexer are recreated. The private backend's Hasura and services and auth
are recreated too, with auth's migrations run again on its empty database, so
every user and API key is gone. Only a new key does this: a bootstrap that
re-runs over the live host keeps its key, and the databases with it. Without a
restore, the deploy refuses the empty `gateway` database until
`database_start_empty` names the floor for one apply, and the object mappings
indexed before are gone as well, as the gateway's node maps only blocks it
archives from then on. To map the chain again, set `create_object_mappings` to the first block
to map and apply, then set it back to `yes` once the indexer logs mappings for
new blocks. Re-archiving from early blocks takes hours.

For the public backend, the first apply:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -replace=module.public.module.host.null_resource.bootstrap -target=module.public.module.mesh
```

The full apply after its key is recorded runs its migrations, which find the
database already current, and its deploy, which requests a new certificate;
Let's Encrypt issues at most five for the same names a week.

The private backend is rebuilt the same way, with `module.private` in place of
`module.public`. Its full apply also deploys auth, whose database, on the
services host, is as it was.

For the gateway, the first apply bootstraps the host and brings up its mesh. Its
deploy, whose migrations reach the services host's Postgres over the mesh, waits
for the full apply, and its node then resyncs from genesis:

```bash
terraform -chdir=resources/terraform/auto-drive-staging plan -out=auto-drive-staging.tfplan \
  -replace=module.files_gateway.module.host.null_resource.bootstrap -target=module.files_gateway.module.mesh
```

A rebuilt gateway or public backend loses its farmer's volumes too. The full
apply runs the farmer's deploy again: its node full-syncs from genesis, about two
days, and the farmer makes a new farm, with a new identity, and plots it. Rewards
already paid stay in the account.

Apply each plan with `manage.sh auto-drive-staging apply`, and once every key is
recorded and applied, run `validate.sh` on each host.
