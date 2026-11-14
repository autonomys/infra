#!/bin/bash

# Runs the host agent from the compose file, .env, scrape config, textfiles
# script and credential Terraform uploaded, then waits until vmagent has written
# to the monitoring host. Terraform re-runs this whenever any of those change,
# so every step must be safe over a live host.

set -euo pipefail

: "${DEPLOY_USER:?DEPLOY_USER is required}"
: "${DEPLOY_DIR:?DEPLOY_DIR is required}"
: "${STAGED_DIR:?STAGED_DIR is required}"
: "${PORT_GUARD:?PORT_GUARD is required}"

# the staged credential goes however this ends
clear_staged() {
  rm -rf "$STAGED_DIR"/*.yml "$STAGED_DIR/.env" "$STAGED_DIR/textfiles.py" "$STAGED_DIR/credentials"
}
trap clear_staged EXIT
trap 'exit 1' HUP INT TERM

# Compose takes the project, the files and the values from the .env in the
# directory it runs in, as it does for anyone running it there by hand
compose_in() {
  local dir="$1"
  shift
  (cd "$dir" && docker compose "$@")
}

# Every check runs against the uploaded files, and only files that pass them
# replace the ones in use, so a refused deploy leaves the host as it was.
service_list="$(compose_in "$STAGED_DIR" config --services)"
mapfile -t services <<< "$service_list"

# images and vmagent's buffer, up to 1 GB, go under Docker's root
avail_kb="$(df -Pk "$(docker info -f '{{.DockerRootDir}}')" | awk 'NR == 2 {print $4}')"
if [ "$avail_kb" -lt 2097152 ]; then
  echo "Only $((avail_kb / 1024)) MB free for Docker; the agent needs 2 GB" >&2
  exit 1
fi

if ! docker plugin inspect loki >/dev/null 2>&1; then
  echo "The loki log driver isn't installed; scripts/installer.sh installs it" >&2
  exit 1
fi

echo "==> Checking published ports"
compose_in "$STAGED_DIR" config --format json --no-env-resolution \
  | PRIVATE_ADDRESSES="" python3 "$PORT_GUARD"

echo "==> Pulling ${services[*]} if missing"
compose_in "$STAGED_DIR" pull --policy missing

install -d -m 0755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$(dirname "$DEPLOY_DIR")"
install -d -m 0750 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR"
install -d -m 0700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR/credentials"
for file in "$STAGED_DIR"/*.yml "$STAGED_DIR/textfiles.py"; do
  install -m 0644 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$file" "$DEPLOY_DIR/$(basename "$file")"
done
install -m 0600 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$STAGED_DIR/.env" "$DEPLOY_DIR/.env"
for file in "$STAGED_DIR"/credentials/*; do
  install -m 0600 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$file" "$DEPLOY_DIR/credentials/$(basename "$file")"
done
clear_staged

echo "==> Starting ${services[*]}"
compose_in "$DEPLOY_DIR" up -d --remove-orphans

# a service that is not healthy within 300s, or restarts or turns unhealthy in
# the 30s after, fails the apply
declare -A started
for service in "${services[@]}"; do
  i=0
  until container="$(compose_in "$DEPLOY_DIR" ps -q "$service" 2>/dev/null)" \
    && [ -n "$container" ] \
    && [ "$(docker inspect -f '{{.State.Health.Status}}' "$container")" = healthy ]; do
    i=$((i + 1))
    if [ "$i" -ge 300 ]; then
      echo "$service not healthy after 300s:" >&2
      compose_in "$DEPLOY_DIR" logs --tail 20 "$service" >&2
      exit 1
    fi
    sleep 1
  done
  started[$service]="$container $(docker inspect -f '{{.RestartCount}}' "$container")"
done
sleep 30
for service in "${services[@]}"; do
  read -r container count <<< "${started[$service]}"
  if [ "$(docker inspect -f '{{.State.Health.Status}} {{.RestartCount}}' "$container")" != "healthy $count" ]; then
    echo "$service restarted or turned unhealthy within 30s of becoming healthy" >&2
    exit 1
  fi
done

successful_writes() {
  { curl -fsS http://127.0.0.1:8430/metrics 2>/dev/null || true; } \
    | awk '/^vmagent_remotewrite_requests_total\{.*status_code="2XX"/ {n += $NF} END {print n + 0}'
}

# A changed credential reaches vmagent without a restart, so writes it made with
# the old one still count: the count has to rise. vmagent writes after each
# scrape, every 15 seconds, so a refused credential or an unreachable monitoring
# host shows here.
echo "==> Waiting for a successful write"
before="$(successful_writes)"
for _ in $(seq 1 45); do
  if [ "$(successful_writes)" -gt "$before" ]; then
    echo "==> Running: ${services[*]}, writing to the monitoring host"
    exit 0
  fi
  sleep 2
done
echo "vmagent hasn't written successfully in 90 seconds:" >&2
compose_in "$DEPLOY_DIR" logs --tail 20 vmagent >&2
exit 1
