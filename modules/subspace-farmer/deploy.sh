#!/bin/bash

# Runs the farmer and its node from the compose file and .env Terraform
# uploaded. Terraform re-runs this whenever either of them or anything else in
# its triggers changes, so every step must be safe over a live host.

set -euo pipefail

: "${DEPLOY_USER:?DEPLOY_USER is required}"
: "${DEPLOY_DIR:?DEPLOY_DIR is required}"
: "${STAGED_DIR:?STAGED_DIR is required}"
: "${PORT_GUARD:?PORT_GUARD is required}"
: "${PUBLIC_TCP_PORTS:?PUBLIC_TCP_PORTS is required}"

clear_staged() {
  rm -f "$STAGED_DIR"/*.yml "$STAGED_DIR/.env"
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

for port in $PUBLIC_TCP_PORTS; do
  if [[ ! "$port" =~ ^[0-9]+$ ]]; then
    echo "Invalid port in PUBLIC_TCP_PORTS: $port" >&2
    exit 1
  fi
done

# Every check runs against the uploaded files, and only files that pass them
# replace the ones in use, so a refused deploy leaves the farmer as it was
echo "==> Checking published ports"
compose_in "$STAGED_DIR" config --format json \
  | PUBLIC_TCP_PORTS="$PUBLIC_TCP_PORTS" python3 "$PORT_GUARD"

# Only images not on the host yet: the references are pinned, so a present
# image is the right one. Pulled before anything stops.
echo "==> Pulling the node and farmer images if missing"
compose_in "$STAGED_DIR" pull --policy missing

# Docker-published ports bypass UFW, so these rules don't gate the containers;
# they keep `ufw status` an honest list of what is open. They carry a comment
# of the farmer's own, which host-bootstrap's firewall pass leaves alone.
echo "==> Opening $PUBLIC_TCP_PORTS/tcp in UFW"
open_ports="$(ufw status | sed -nE 's|^([0-9]+)/tcp +ALLOW +Anywhere +# farmer-port$|\1|p')"
for port in $open_ports; do
  if [[ " $PUBLIC_TCP_PORTS " != *" $port "* ]]; then
    ufw delete allow "$port/tcp" >/dev/null
  fi
done
for port in $PUBLIC_TCP_PORTS; do
  ufw allow "$port/tcp" comment 'farmer-port' >/dev/null
done

install -d -m 0755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$(dirname "$DEPLOY_DIR")"
install -d -m 0750 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR"
for file in "$STAGED_DIR"/*.yml; do
  install -m 0644 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$file" "$DEPLOY_DIR/$(basename "$file")"
done
install -m 0600 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$STAGED_DIR/.env" "$DEPLOY_DIR/.env"
clear_staged

# The loki driver's local copy, which `docker logs` reads, holds only a
# container's current run, so the error a restarted container exited with is
# only in Loki
fail() {
  local service container error project=""
  echo "$1" >&2
  for service in node farmer; do
    container="$(compose_in "$DEPLOY_DIR" ps -aq "$service" 2>/dev/null || true)"
    [ -n "$container" ] || continue
    project="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$container")"
    echo "$service: $(docker inspect -f '{{.State.Status}}, {{.RestartCount}} restarts' "$container")" >&2
    error="$(docker logs "$container" 2>&1 | grep ' ERROR ' | tail -1 || true)"
    if [ -n "$error" ]; then echo "$service's last error in its current run: $error" >&2; fi
  done
  if [ -n "$project" ]; then
    echo "earlier runs are in Loki: {host=\"$(hostname)\", compose_project=\"$project\"} |= \"ERROR\"" >&2
  fi
  exit 1
}

echo "==> Starting the node and the farmer"
compose_in "$DEPLOY_DIR" up -d || fail "docker compose up failed"

# not running within 300s, or restarted within the 30s after, fails the apply
# before old images are pruned
declare -A started
for service in node farmer; do
  i=0
  until container="$(compose_in "$DEPLOY_DIR" ps -q "$service" 2>/dev/null)" \
    && [ -n "$container" ] \
    && [ "$(docker inspect -f '{{.State.Status}}' "$container")" = running ]; do
    i=$((i + 1))
    if [ "$i" -ge 300 ]; then fail "$service not running after 300s"; fi
    sleep 1
  done
  started[$service]="$container $(docker inspect -f '{{.RestartCount}}' "$container")"
done
sleep 30
for service in node farmer; do
  read -r container count <<< "${started[$service]}"
  if [ "$(docker inspect -f '{{.State.Status}} {{.RestartCount}}' "$container")" != "running $count" ]; then
    fail "$service restarted or stopped within 30s of starting"
  fi
done

docker image prune -af

echo "==> Running: node and farmer"
