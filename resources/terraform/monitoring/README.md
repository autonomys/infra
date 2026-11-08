# Fleet monitoring host

Terraform for `monitoring-loki`, the bare-metal box that receives the fleet's logs
at `logging.subspace.network` and serves Grafana at `grafana.subspace.network`.
The project creates no cloud resources. It provisions an existing box over SSH
through `modules/monitoring-host`.

## Stack

| Component | Image | Listens on | Role |
|---|---|---|---|
| Traefik | `traefik:v3.7.17` | `:80`, `:443` (host network) | TLS termination, Let's Encrypt, routing |
| Loki | `grafana/loki:3.6.20` | `127.0.0.1:3100` | Fleet container logs, kept 30 days |
| Grafana | `grafana/grafana:13.2.5` | `127.0.0.1:3000` | Dashboards over Loki |

Requests reach the box through the Cloudflare proxy, then UFW (Cloudflare ranges
only), then Traefik. Grafana reads Loki directly on the compose network.

### Endpoints

| Request | Served by | Auth |
|---|---|---|
| `POST https://logging.subspace.network/loki/api/v1/push` | Loki | None |
| `GET https://logging.subspace.network/ready` | Loki | None |
| `https://grafana.subspace.network/*` | Grafana | Grafana login |
| `GET http://<either host>/.well-known/acme-challenge/*` | Traefik | None |

Any other request to `logging.subspace.network` gets a 403 from Cloudflare and a
404 from Traefik. Loki can only be queried from the box itself, which is how
Grafana reads it.

### Exposure

- Only proxied DNS records point at the box. Its address is kept in Infisical,
  and `host_ipv4` is marked sensitive so plans don't print it.
- UFW denies incoming by default, allows 22 from anywhere, and allows 80 and 443
  from Cloudflare's published ranges only.
- Ports Docker publishes bypass UFW, so containers publish on `127.0.0.1` only
  and Traefik runs in host networking.
- Traefik refuses handshakes below TLS 1.2 or for any name it doesn't serve
  (`sniStrict`).
- SSH allows only key login. Root login is off, `ubuntu` is the only login user,
  and fail2ban watches `sshd`.
- Loki takes pushes without credentials, so it rejects any push larger than
  16 MB, compressed or decompressed.
- Grafana requires a login for everything. Anonymous access, sign-up, basic auth
  on the API, snapshots and public dashboards are off, and its health endpoint
  doesn't show the version without a login.
- Certificates come from Let's Encrypt over HTTP-01 through the proxy, so the box
  holds no DNS API token. Renewals depend on the Loki rule in the `dns` project
  allowing the challenge path.

## Layout

| Path | Contents |
|---|---|
| `resources/terraform/monitoring/` | This project, `installimage.conf`, `first-boot.sh`, `validate.sh` |
| `modules/monitoring-host/` | Compose file, Loki config, Traefik routes, provisioning resources |
| `modules/monitoring-host/grafana/` | Grafana's datasource, dashboard providers and dashboards |
| `scripts/monitoring-host-bootstrap.sh` | Packages, GRUB, UFW, SSH, fail2ban, unattended upgrades, data directories |
| `scripts/installer.sh` | Shared with the fleet: Docker, journald and kernel settings |

On the box:

| Path | Contents |
|---|---|
| `/home/ubuntu/monitoring/` | `docker-compose.yml`, `.env`, `loki/config.yml`, `traefik/dynamic.yml`, `grafana/` |
| `/home/ubuntu/monitoring/secrets/` | Grafana admin username and password (directory mode 0700) |
| `/srv/monitoring/loki/` | Loki's chunks, index and WAL |
| `/srv/monitoring/grafana/` | Grafana's database: users, preferences, dashboards made in the UI |
| `/srv/monitoring/traefik/acme.json` | Let's Encrypt account and certificate, re-issued if lost |

Swap, `/boot`, `/` and `/srv` are each RAID 1 across both disks. Data lives on
`/srv`, so log growth can't fill `/`.

## Terraform resources

| Resource | Does | Re-runs when |
|---|---|---|
| `null_resource.setup_monitoring_host` | Runs `installer.sh`, then `monitoring-host-bootstrap.sh` | Either script or the host address changes |
| `null_resource.deploy_monitoring_stack` | Uploads the compose file, configs, Grafana files, admin secrets and `.env`, sets the hostname, starts the stack, waits for Loki and Grafana, resets the Grafana admin password | Any of those files, the admin credentials or the instance settings change |

Both steps are safe to re-run over a live host. A re-run of the setup step
upgrades Docker if a newer release is out, which restarts every container.

## Configuration

| Setting | Where |
|---|---|
| `host_ipv4`, `letsencrypt_email`, `grafana_admin_user`, `grafana_admin_password` | `common.auto.tfvars`, stored in Infisical at `/monitoring` |
| `ssh_agent_identity` | Your local `user.auto.tfvars`, not stored in Infisical |
| Hostname, Loki and Grafana domains | `main.tf` |
| Image versions | `modules/monitoring-host/docker-compose.yml` |
| Retention, ingestion limits | `modules/monitoring-host/loki/config.yml` |
| Routed paths, TLS options | `modules/monitoring-host/traefik/dynamic.yml.tftpl` |
| Grafana settings | `environment` of the `grafana` service in `docker-compose.yml` |
| Grafana datasource and dashboards | `modules/monitoring-host/grafana/` |

## Deploying a change

Prerequisites:

- `INFISICAL_CLIENT_ID`, `INFISICAL_CLIENT_SECRET` and `INFISICAL_INFRA_PROJECT_ID`
  set
- Terraform Cloud workspace `monitoring` (org `subspace-sre`) in local execution
  mode
- `user.auto.tfvars` with your `ssh_agent_identity`, and that key loaded in your
  SSH agent (`ssh-add -l`)

```bash
./resources/terraform/manage.sh monitoring init
./resources/terraform/manage.sh monitoring plan
./resources/terraform/manage.sh monitoring apply
./resources/terraform/monitoring/validate.sh
```

## Building the box from scratch

1. Boot the box into the provider's rescue system with your SSH key, and check
   the disks and boot mode:

   ```bash
   lsblk -d -o NAME,MODEL,SERIAL,SIZE,TYPE
   for d in /dev/sda /dev/sdb; do smartctl -H -i "$d"; done
   [ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
   ```

2. Install the OS:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/monitoring/installimage.conf -o /autosetup
   installimage
   ```

   On hardware this config hasn't been used with, first run `installimage`
   without `/autosetup` and compare its drive names, image filename and boot mode
   with `installimage.conf`.

3. Before rebooting, record the new system's host key from the rescue session.
   With this config `/` is `md2`:

   ```bash
   mkdir -p /mnt/newroot && mount -o ro /dev/md2 /mnt/newroot
   ssh-keygen -lf /mnt/newroot/etc/ssh/ssh_host_ed25519_key.pub
   umount /mnt/newroot
   ```

4. Reboot, check the host key matches, and as root create the deploy user:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/monitoring/first-boot.sh -o first-boot.sh
   bash first-boot.sh
   ```

   This creates `ubuntu` with passwordless sudo and the key used for the rescue
   system.

5. Apply this project as in [Deploying a change](#deploying-a-change). DNS already
   points at the box, so the fleet's pushes arrive as soon as Loki is up.

## Operations

### Checking the box

`validate.sh [ssh-host]` checks the disks, RAID and boot code, SSH and firewall
settings, the stack, the certificate and Traefik's routing. From your machine it
checks that the origin's 443 and 3100 are unreachable and that Cloudflare passes
only the allowed requests. It changes nothing. `ssh-host` defaults to
`monitoring-loki` from your SSH config.

### Adding an SSH user

Append their public key to `/home/ubuntu/.ssh/authorized_keys`.

### Grafana users

The admin adds users under Administration > Users and access. Users live in
Grafana's database on `/srv`, not in the repo.

### Grafana admin password

Change `grafana_admin_password` in `common.auto.tfvars`, then plan and apply. The
deploy resets the admin password to it, which also undoes any change made in the
UI. `grafana_admin_user` only takes effect when Grafana creates its database, so
rename the admin in the UI as well if it changes.

### Dashboards

Dashboards in `modules/monitoring-host/grafana/dashboards/<folder>/` are
provisioned into the matching Grafana folder, and each folder needs a provider in
`grafana/provisioning/dashboards/repo.yml`. Grafana won't save UI edits over a
provisioned dashboard. Edit it in the UI, export it as JSON, replace the file in
the repo, and apply. Grafana picks up dashboard changes without a
restart. Dashboards created in the UI stay in Grafana's database.

### Picking up new Cloudflare ranges

The bootstrap fetches Cloudflare's ranges each time it runs. To re-run it:

```bash
terraform -chdir=resources/terraform/monitoring plan \
  -replace=module.monitoring.null_resource.setup_monitoring_host \
  -out=monitoring.tfplan
./resources/terraform/manage.sh monitoring apply
```

### Replacing a disk

The RAID rebuild doesn't copy boot code. Once `/proc/mdstat` shows every array in
sync, on a BIOS box:

```bash
sudo grub-install --target=i386-pc /dev/sdX
sudo dpkg-reconfigure grub-pc    # keep both disks selected
```

Then run `validate.sh`.

## DNS

`logging`, `grafana`, `grafana.vmetrics` and `vmetrics` (`.subspace.network`) are
proxied A records in the `dns` project, with the address from `proxied.json`. The
Loki rule is in `cloudflare_ruleset.subspace_network_firewall_custom` in the same
project.

## Rules for this host

- Point only proxied records at it.
- Keep its address out of this repo, PR descriptions and commit messages.
- Publish container ports on `127.0.0.1` only.
