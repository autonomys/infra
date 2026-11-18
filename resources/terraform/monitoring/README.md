# Fleet monitoring host

Terraform for `monitoring-loki`, the bare-metal box that receives the fleet's logs
at `logging.subspace.network`, serves Grafana at `grafana.subspace.network`, takes
metric writes at `vmetrics.subspace.network`, keeps metrics, and sends alerts to
Slack #alerts. The project creates no cloud resources. It provisions an existing
box over SSH through `modules/monitoring-host`.

## Stack

| Component | Image | Listens on | Role |
|---|---|---|---|
| Traefik | `traefik:v3.7.19` | `:80`, `:443` (host network) | TLS termination, Let's Encrypt, routing |
| Loki | `grafana/loki:3.6.21` | `127.0.0.1:3100` | Fleet container logs, kept 30 days |
| Grafana | `grafana/grafana:13.2.6` | `127.0.0.1:3000` | Dashboards over logs and metrics; alert silences |
| VictoriaMetrics | `victoriametrics/victoria-metrics:v1.155.0` | `127.0.0.1:8428` | Metrics, kept 90 days |
| vmagent | `victoriametrics/vmagent:v1.155.0` | `127.0.0.1:8429` (host network) | Scrapes the box's own metrics into VictoriaMetrics |
| node_exporter | `prom/node-exporter:v1.12.1` | `127.0.0.1:9100` (host network) | Host, RAID and filesystem metrics |
| smartctl_exporter | `prometheuscommunity/smartctl-exporter:v0.15.0` | `127.0.0.1:9633` (host network) | SMART data for every disk |
| vmalert | `victoriametrics/vmalert:v1.155.0` | `127.0.0.1:8880` | Evaluates the alert rules |
| Alertmanager | `prom/alertmanager:v0.34.2` | `127.0.0.1:9093` | Sends alerts to Slack #alerts and the Watchdog heartbeat to the relay |
| vmauth | `victoriametrics/vmauth:v1.155.0` | `127.0.0.1:8427` | Checks the metrics write credentials and passes the write paths to VictoriaMetrics |
| Watchdog relay | `python:3.13.18-alpine3.24` | compose network only | Turns each Watchdog notification into the GET that Uptime Kuma 1.x's push route needs |

Requests reach the box through the Cloudflare proxy, then UFW (Cloudflare ranges
only), then Traefik. Grafana reads Loki, VictoriaMetrics and Alertmanager on the
compose network.

### Endpoints

| Request | Served by | Auth |
|---|---|---|
| `POST https://logging.subspace.network/loki/api/v1/push` | Loki | None |
| `GET https://logging.subspace.network/ready` | Loki | None |
| `https://grafana.subspace.network/*` except `/metrics` | Grafana | Grafana login |
| `POST https://vmetrics.subspace.network/write` | VictoriaMetrics, through vmauth | Basic auth, the credential Auto Drive's services share |
| `POST https://vmetrics.subspace.network/api/v1/write` | VictoriaMetrics, through vmauth | Basic auth, the credential the host agents share |
| `GET http://<any of the three hosts>/.well-known/acme-challenge/*` | Traefik | None |

Any other request to `logging.subspace.network` gets a 403 from Cloudflare and a
404 from Traefik, and any other request to `vmetrics.subspace.network` a 404 from
Traefik. Loki and VictoriaMetrics can only be queried from the box itself, which
is how Grafana reads them.

Writes to `/write` use the InfluxDB line protocol. VictoriaMetrics stores each
field as a series named `<measurement>_<field>`, with the tags as labels. Writes
to `/api/v1/write` use Prometheus remote write, from the host agents on the other
servers (`resources/terraform/host-agents`).

### Exposure

- Only proxied DNS records point at the box. Its address is kept in Infisical,
  and `host_ipv4` is marked sensitive so plans don't print it. Its host key is
  kept there too: scanners index SSH host keys, so a published key would give
  the address away.
- Terraform checks the box's ECDSA host key (`host_key`) before sending
  anything, so a server answering in its place gets none of the secrets.
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
  on the API, snapshots and public dashboards are off. Its health endpoint
  doesn't show the version without a login, but the login page does, as does the
  compose file in this repo. Traefik doesn't route its `/metrics` page, which
  Grafana serves without a login and which also lists its users and datasources.
- Metric writes need a write credential, which vmauth checks before passing
  the request on. Each credential maps to one write path, so it can't read
  metrics or reach any other VictoriaMetrics path, and vmauth doesn't log
  rejected credentials.
- Metric reads and alerting have no public route. Their ports are on `127.0.0.1`
  only, and Grafana reads them on the box.
- smartctl_exporter runs privileged so it can read the disks. It listens on
  `127.0.0.1` only.
- Alertmanager reads the Slack webhook, the relay the Uptime Kuma push URL, and
  vmauth the write credentials from files in `secrets/`, so none appears in a
  config file or API.
- Certificates come from Let's Encrypt over HTTP-01 through the proxy, so the box
  holds no DNS API token. Renewals depend on the Loki rule in the `dns` project
  allowing the challenge path.

## Layout

| Path | Contents |
|---|---|
| `resources/terraform/monitoring/` | This project, `installimage.conf`, `first-boot.sh`, `validate.sh` |
| `modules/monitoring-host/` | Compose file, Loki config, Traefik routes, provisioning resources |
| `modules/monitoring-host/grafana/` | Grafana's datasources, dashboard providers and dashboards |
| `modules/monitoring-host/vmagent/` | What the box scrapes |
| `modules/monitoring-host/vmalert/` | Alert rules (`rules/`) and their unit tests (`tests/`) |
| `modules/monitoring-host/alertmanager/` | Alert routing |
| `modules/monitoring-host/vmauth/` | Template for vmauth's credentials file |
| `modules/monitoring-host/watchdog-relay/` | The Watchdog relay to Uptime Kuma |
| `scripts/monitoring-host-bootstrap.sh` | Packages, GRUB, UFW, SSH, fail2ban, unattended upgrades, data directories |
| `scripts/installer.sh` | Shared with the fleet: Docker, journald and kernel settings |

On the box:

| Path | Contents |
|---|---|
| `/home/ubuntu/monitoring/` | `docker-compose.yml`, `.env`, and the config directories above |
| `/home/ubuntu/monitoring/secrets/` | Grafana admin login, Slack webhook, Uptime Kuma push URL, vmauth's credentials file (directory mode 0700) |
| `/srv/monitoring/loki/` | Loki's chunks, index and WAL |
| `/srv/monitoring/grafana/` | Grafana's database: users, preferences, dashboards made in the UI |
| `/srv/monitoring/victoriametrics/` | Metrics |
| `/srv/monitoring/vmagent/` | vmagent's buffer while VictoriaMetrics is unreachable, capped at 1 GB |
| `/srv/monitoring/alertmanager/` | Silences and the notification log |
| `/var/lib/node_exporter/textfile/disks.prom` | The expected disk count, for the DiskMissing rule |
| `/srv/monitoring/traefik/acme.json` | Let's Encrypt account and certificate, re-issued if lost |

Swap, `/boot`, `/` and `/srv` are each RAID 1 across both disks. Data lives on
`/srv`, so log growth can't fill `/`.

## Terraform resources

| Resource | Does | Re-runs when |
|---|---|---|
| `null_resource.setup_monitoring_host` | Runs `installer.sh`, then `monitoring-host-bootstrap.sh` | Either script, the host address or its host key changes |
| `null_resource.deploy_monitoring_stack` | Uploads the compose file, configs, secrets and `.env`, fetches the third-party dashboards, sets the hostname and expected disk count, starts the stack, waits for each service, resets the Grafana admin password | Any of those files, the dashboard pins, the secrets or the instance settings change, or the setup step runs |

Both steps are safe to re-run over a live host. A re-run of the setup step
upgrades Docker if a newer release is out, which restarts every container.

## Configuration

| Setting | Where |
|---|---|
| `host_ipv4`, `letsencrypt_email`, `grafana_admin_user`, `grafana_admin_password`, `alertmanager_slack_webhook_url`, `watchdog_push_url`, `host_key`, `vmetrics_username`, `vmetrics_password`, `vmetrics_fleet_username`, `vmetrics_fleet_password` | `common.auto.tfvars`, stored in Infisical at `/monitoring` |
| `ssh_agent_identity` | Your local `user.auto.tfvars`, not stored in Infisical |
| Hostname, Loki, Grafana and vmetrics domains, expected disk count | `main.tf` |
| Image versions | `modules/monitoring-host/docker-compose.yml` |
| Retention, ingestion limits | `modules/monitoring-host/loki/config.yml` |
| Routed paths, TLS options | `modules/monitoring-host/traefik/dynamic.yml.tftpl` |
| Grafana settings | `environment` of the `grafana` service in `docker-compose.yml` |
| Grafana datasources and dashboards | `modules/monitoring-host/grafana/` |
| Third-party dashboards (grafana.com ID, revision, SHA-256) | `grafana_com_dashboards` in `modules/monitoring-host/main.tf` |
| Metrics retention, insert size cap | `victoriametrics` command in `docker-compose.yml` |
| What the box scrapes | `modules/monitoring-host/vmagent/scrape.yml` |
| Alert rules | `modules/monitoring-host/vmalert/rules/` |
| Alert routing, grouping and repeats | `modules/monitoring-host/alertmanager/alertmanager.yml` |
| Paths each write credential may reach | `modules/monitoring-host/vmauth/auth.yml.tftpl` |

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

3. Before rebooting, record the new system's host keys from the rescue session:
   the ed25519 fingerprint to check your first login, and the ECDSA public key,
   without its comment, for `host_key` in `common.auto.tfvars`, which Terraform
   checks. With this config `/` is `md2`:

   ```bash
   mkdir -p /mnt/newroot && mount -o ro /dev/md2 /mnt/newroot
   ssh-keygen -lf /mnt/newroot/etc/ssh/ssh_host_ed25519_key.pub
   awk '{print $1, $2}' /mnt/newroot/etc/ssh/ssh_host_ecdsa_key.pub
   umount /mnt/newroot
   ```

4. Reboot, check the host key matches, and as root create the deploy user:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/autonomys/infra/main/resources/terraform/monitoring/first-boot.sh -o first-boot.sh
   bash first-boot.sh
   ```

   This creates `ubuntu` with passwordless sudo and the key used for the rescue
   system.

5. Apply this project as in [Deploying a change](#deploying-a-change). The new
   `host_key` makes Terraform set the box up and deploy the stack again. DNS
   already points at the box, so the fleet's pushes arrive as soon as Loki is up.

## Operations

### Checking the box

`validate.sh [ssh-host]` checks the disks, RAID and boot code, SSH and firewall
settings, the stack, scraping, alert rules and notifications, the certificate and
Traefik's routing. From your machine it checks that the origin's service ports are
unreachable and that Cloudflare passes only the allowed requests. It changes nothing. `ssh-host` defaults to
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

Metrics > Fleet health summarises every server that sends metrics: whether it
reports, CPU, memory and filesystems, RAID arrays, each disk's SMART health and
wear, boot code, firing alerts, and trends.

Metrics > Auto Drive staging shows the Auto Drive staging stack on Chronos: its
four hosts, the nodes, the DAG index, the gateway database's backups and the
backend processes, from the host agents' metrics, the containers' logs and the
metrics the backends send. A tile reads "No data" when its source is missing,
and the panel under the tiles lists what the dashboard doesn't cover. Its
Publish workers tile counts heartbeat samples, so it relies on VictoriaMetrics
keeping every sample: change the tile before setting `-dedup.minScrapeInterval`.

### Alerts

Alertmanager posts to #alerts, one message per server, with critical alerts
repeated every 4 hours and warnings daily until they resolve. To see or silence
alerts, open Alerting > Silences or Alert groups in Grafana and pick the
Alertmanager datasource.

The Watchdog alert always fires. Alertmanager sends it every minute to the relay,
which pushes to an Uptime Kuma push monitor (heartbeat interval 180 s, 1 retry).
Uptime Kuma runs elsewhere, so it reports when this box or its alerting stops.

To send a test alert, which resolves itself after 5 minutes, run this on the box:

```bash
sudo docker exec alertmanager amtool alert add TestAlert severity=warning host=monitoring-loki \
  --annotation='summary="Test alert, please ignore"' --alertmanager.url=http://localhost:9093
```

### Forgetting a server

ServerSilent fires for a server 15 minutes after it stops sending, and keeps
firing until it sends again, however long that takes. Once a server is gone for
good (see Removing a server in the host agents' README) and ServerSilent has
fired for it, delete its last-scrape record on the box:

```bash
q='host:last_scrape_timestamp:max{host="<server>"}'
curl -fsS http://127.0.0.1:8428/api/v1/admin/tsdb/delete_series --data-urlencode "match[]=$q"
sleep 60
curl -fsS http://127.0.0.1:8428/api/v1/query --data-urlencode "query=$q"
```

The query should return no result, and the alert resolves. Deleting sooner
doesn't stick: for 5 minutes after a server's last scrape vmalert still sees it
and writes the record again.

### Changing alert rules

Edit or add a file in `modules/monitoring-host/vmalert/rules/`, cover it in
`vmalert/tests/`, and run the tests before applying:

```bash
for f in modules/monitoring-host/vmalert/tests/*.yml; do
  docker run --rm -v "$PWD/modules/monitoring-host/vmalert":/vmalert:ro -w /vmalert/tests \
    victoriametrics/vmalert-tool:v1.155.0 unittest --files="/vmalert/tests/$(basename "$f")"
done
```

The apply restarts vmalert with the new rules. Every series carries `host`, so a
rule can group by server.

### Updating a third-party dashboard

The Metrics folder also holds dashboards fetched from grafana.com at the
revision pinned in `grafana_com_dashboards`, and the deploy refuses a download
whose SHA-256 doesn't match. To move to a new revision, update both:

```bash
curl -fsSL https://grafana.com/api/dashboards/<id>/revisions/<revision>/download | shasum -a 256
```

### Metrics write credentials

| Credential | Variables | Senders | Path | vmauth name |
|---|---|---|---|---|
| Auto Drive | `vmetrics_username`, `vmetrics_password` | Auto Drive's services, from `VICTORIA_USERNAME` and `VICTORIA_PASSWORD` | `/write` | `metrics-writer` |
| Host agents | `vmetrics_fleet_username`, `vmetrics_fleet_password` | The host agents; the `host-agents` project holds the same pair | `/api/v1/write` | `fleet` |

To rotate one, change it in `common.auto.tfvars`, then plan and apply. vmauth
reloads its file within 30 seconds without a restart, and the old credential
stops working at that point, so update its senders at the same time. The host
agents buffer up to 1 GB each while their writes are refused, and send it once
they have the new credential. `vmauth_user_requests_total{username="<vmauth
name>"}` in VictoriaMetrics counts each credential's requests.

### Picking up new Cloudflare ranges

The bootstrap fetches Cloudflare's ranges each time it runs. To re-run it, and
the stack deploy after it:

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
sudo dpkg-reconfigure grub-pc    # select both disks
```

smartctl only sees the disks that were there when it started, so restart it:

```bash
cd ~/monitoring && sudo docker compose restart smartctl-exporter
```

Then run `validate.sh`. RaidDegraded and DiskMissing clear once the arrays are in
sync. If a server's number of disks changes, update `disks` in `main.tf`.

## DNS

`logging`, `grafana` and `vmetrics` (`.subspace.network`) are
proxied A records in the `dns` project, with the address from `proxied.json`. The
Loki rule is in `cloudflare_ruleset.subspace_network_firewall_custom` in the same
project. `vmetrics` has no Cloudflare rule; Traefik and vmauth restrict it.

## Rules for this host

- Point only proxied records at it.
- Keep its address and host keys out of this repo, PR descriptions and commit
  messages.
- Publish container ports on `127.0.0.1` only.
