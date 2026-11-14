# Host agents

Terraform for the host agent: a small compose stack on each bare-metal server
that sends the server's host, RAID, SMART and boot metrics to the monitoring host
at `vmetrics.subspace.network`, where vmalert's disk rules evaluate them. The
project creates no cloud resources. It provisions existing servers over SSH
through `modules/host-agent`, independently of whatever else a server runs.

## Agent

| Component | Listens on | Role |
|---|---|---|
| vmagent | `127.0.0.1:8430` | Scrapes the other components and any node metrics port, writes everything to the monitoring host, and buffers up to 1 GB on disk while it can't |
| node_exporter | `127.0.0.1:9100` | Host, RAID and filesystem metrics, plus the textfiles below |
| smartctl_exporter | `127.0.0.1:9633` | SMART data for every disk |
| textfiles | nothing (no network) | Every 6 hours, writes the server's expected disk count and whether each disk `/boot` lives on has GRUB's legacy BIOS boot code |

All run in the host network, from the images pinned in `local.images`. vmagent
listens on 8430 rather than its default 8429, which the node template's own
vmagent publishes on some servers. Their logs go to Loki through the loki log
driver, as the rest of the fleet's do.

Every series carries `host=<server name>` and `instance=<server name>`, with the
name as in `local.agents`. A server sends about 3,200 series at a 15-second
scrape interval, plus its node's metrics where `scrape_ports` lists them.

### On each server

The deploy user is the server's SSH user, and `~` is that user's home.

| Path | Contents |
|---|---|
| `~/deploy/host-agent/` | `docker-compose.yml`, `.env` (mode 0600), `scrape.yml`, `textfiles.py`; run `docker compose` here by hand |
| `~/deploy/host-agent/credentials/` | The write credential (directory mode 0700, files 0600) |
| `~/subspace/host-agent/` | Where the deploy stages uploads; emptied after each deploy |
| Volume `host-agent_vmagent-data` | vmagent's buffer while the monitoring host is unreachable or refuses writes |
| Volume `host-agent_textfiles` | `disks.prom` (`node_disks_expected`) and `bootloader.prom` (`node_boot_efi`, `node_bootloader_grub_present{device}`) |

The compose project is `host-agent`, so it doesn't collide with a server's other
stacks.

### Exposure

- Nothing listens beyond `127.0.0.1`, and nothing is published through Docker.
  The deploy runs `scripts/compose-port-guard.py` against the compose file
  before starting anything.
- The server needs only outbound HTTPS to `vmetrics.subspace.network` and to
  Loki.
- The credential can only write, and only through `/api/v1/write`. vmauth on the
  monitoring host checks it; see the monitoring project's README.
- smartctl_exporter and the textfiles container run privileged to read the
  disks. The textfiles container has no network and a read-only root
  filesystem, and only opens disks to read their first sector.
- Terraform checks each server's SSH host key before sending anything.

## Terraform resources

| Resource | Does | Re-runs when |
|---|---|---|
| `module.host_agent["<server>"].null_resource.deploy` | Uploads the compose file, scrape config, textfiles script, `.env` and credential to the staging directory, then runs `deploy.sh`, which checks there are 2 GB free and the loki log driver is installed, checks the published ports, pulls missing images, installs the files, starts the stack, waits for every container to turn healthy and stay so for 30 seconds, and waits up to 90 seconds for vmagent's first successful write | The compose file, `.env` (images, scrape config, textfiles script, disk count), credential, `deploy.sh`, port guard, or the server's address or SSH user changes |

Re-running is safe on a live server. Only the containers whose configuration
changed are recreated, and vmagent keeps its buffer.

## Configuration

| Setting | Where |
|---|---|
| Each agent: SSH user, disk count, node metrics ports | `local.agents` in `main.tf` |
| Image versions, Loki and vmetrics URLs | `local.images`, `local.loki_url`, `local.vmetrics_url` in `main.tf` |
| `servers` (each server's address and host key), `vmetrics_fleet_username`, `vmetrics_fleet_password` | `common.auto.tfvars`, stored in Infisical at `/host-agents` |
| `ssh_agent_identity` | Your local `user.auto.tfvars`, not stored in Infisical |
| Containers, listening ports | `modules/host-agent/compose/docker-compose.yml` |
| What vmagent scrapes | `modules/host-agent/scrape.yml.tftpl` |
| Alert rules | `modules/monitoring-host/vmalert/rules/` (the monitoring project) |

## Deploying a change

Prerequisites:

- `INFISICAL_CLIENT_ID`, `INFISICAL_CLIENT_SECRET` and `INFISICAL_INFRA_PROJECT_ID`
  set
- Terraform Cloud workspace `host-agents` (org `subspace-sre`) in local execution
  mode
- `user.auto.tfvars` with your `ssh_agent_identity`, and that key loaded in your
  SSH agent and authorised for each server's SSH user

```bash
./resources/terraform/manage.sh host-agents init
./resources/terraform/manage.sh host-agents plan
./resources/terraform/manage.sh host-agents apply
./resources/terraform/host-agents/validate.sh <server> <ssh-host>
```

A change to the module re-deploys every server. To roll it out one server at a
time, plan with `-target='module.host_agent["<server>"]'`.

## Adding a server

1. Check the server has Docker with the Compose plugin and the loki log driver
   (`scripts/installer.sh` installs both), 2 GB free for Docker, and nothing on
   ports 8430, 9100 and 9633 (`ss -ltn`).
2. Record its ECDSA host key, which Terraform checks: Terraform's SSH client asks
   for ECDSA before ed25519, so that is the key a server with both presents.
   Read `/etc/ssh/ssh_host_ecdsa_key.pub` over an SSH session that checked a host
   key you already trust, from the server inventory or your first login:

   ```bash
   ssh -o HostKeyAlgorithms=ssh-ed25519 <server> 'cat /etc/ssh/ssh_host_ecdsa_key.pub'
   ```

3. Add the server to `local.agents` in `main.tf`: SSH user, number of
   disks, and `scrape_ports` for any node metrics endpoint on `127.0.0.1` (a
   Subspace node's is usually 9615, a DSN bootstrap node's 9616).
4. Add its address (`ipv4`) and ECDSA host key (`host_key`) under the same name in
   `servers` in `common.auto.tfvars`.
5. Plan, check that only that server's module is added, apply, and run
   `validate.sh`.
6. If the node template's old vmagent is on the server, remove it and its empty
   volume. It writes to an address that never accepted its data:

   ```bash
   docker rm -f vmagent
   docker volume rm subspace_vmagentdata
   ```

## Operations

### Checking a server

`validate.sh <server> <ssh-host> [monitoring-ssh-host]` checks on the server that
the four containers are healthy, that the agent's ports are on loopback only,
the credential's and `.env`'s file modes, that vmagent has written and dropped
nothing, and that node_exporter serves both textfiles. On the monitoring host it checks that every scrape target
is up and fresh, that smartctl sees the expected number of disks, and that the
boot disks carry GRUB or the server boots UEFI. It changes nothing.

Grafana's Metrics > Fleet health dashboard shows every server's state at a
glance, including each disk's SMART health and wear.

### Changing a server's disk count

Update `disks` in `local.agents`, then plan and apply. DiskMissing compares it
with what smartctl sees.

### Rotating the credential

The monitoring project's vmauth holds the same pair as `vmetrics_fleet_username`
and `vmetrics_fleet_password`. Change it there and apply, then change it here and
apply. Between the two applies the agents' writes are refused, and each buffers
up to 1 GB, which it sends once it has the new credential.

### Removing a server

Remove it from `local.agents` and `servers`, then apply. Terraform
forgets the deploy but doesn't touch the server, so stop the agent there:

```bash
cd ~/deploy/host-agent && docker compose down --volumes
```

## Rules for these hosts

- Keep the agent's ports on `127.0.0.1`.
- Keep server addresses and host keys out of this repo, PR descriptions and
  commit messages: scanners index SSH host keys, so a key gives its server's
  address away.
- Change servers one at a time, and run `validate.sh` after each.
