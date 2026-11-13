#!/bin/bash

# Runs the gateway's services from the compose files and .env Terraform
# uploaded. Terraform re-runs this whenever any of them or anything else in its
# triggers changes, so every step must be safe over a live host.

set -euo pipefail

: "${DEPLOY_USER:?DEPLOY_USER is required}"
: "${DEPLOY_DIR:?DEPLOY_DIR is required}"
: "${STAGED_DIR:?STAGED_DIR is required}"
: "${PORT_GUARD:?PORT_GUARD is required}"
PUBLIC_TCP_PORTS="${PUBLIC_TCP_PORTS:-}"
PRIVATE_ADDRESSES="${PRIVATE_ADDRESSES:-}"
COMPOSE_FILES=(docker-compose.yml docker-compose.log-cap.yml)
STAGED=("${COMPOSE_FILES[@]/#/$STAGED_DIR/}" "$STAGED_DIR/.env")

trap 'rm -f "${STAGED[@]}"' EXIT
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
read -r -a services <<< "$(compose_in "$STAGED_DIR" config --services | paste -sd ' ' -)"

echo "==> Checking published ports"
compose_in "$STAGED_DIR" config --format json --no-env-resolution \
  | PUBLIC_TCP_PORTS="$PUBLIC_TCP_PORTS" PRIVATE_ADDRESSES="$PRIVATE_ADDRESSES" python3 "$PORT_GUARD"

# Only images not on the host yet, so a tag pushed again upstream can't recreate
# a service during an unrelated deploy. A tag changed in Terraform still pulls,
# before anything stops.
echo "==> Pulling ${services[*]} if missing"
compose_in "$STAGED_DIR" pull --policy missing

install -d -m 0755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$(dirname "$DEPLOY_DIR")"
install -d -m 0750 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR"
for file in "${COMPOSE_FILES[@]}"; do
  install -m 0644 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$STAGED_DIR/$file" "$DEPLOY_DIR/$file"
done
install -m 0600 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$STAGED_DIR/.env" "$DEPLOY_DIR/.env"
rm -f "${STAGED[@]}"

echo "==> Starting ${services[*]}"
compose_in "$DEPLOY_DIR" up -d

# a service that is not running, or restarts within 30s, fails the apply before
# old images are pruned
declare -A started
for service in "${services[@]}"; do
  i=0
  until container="$(compose_in "$DEPLOY_DIR" ps -q "$service" 2>/dev/null)" \
    && [ -n "$container" ] \
    && [ "$(docker inspect -f '{{.State.Status}}' "$container")" = running ]; do
    i=$((i + 1))
    if [ "$i" -ge 300 ]; then echo "$service not running after 300s" >&2; exit 1; fi
    sleep 1
  done
  started[$service]="$container $(docker inspect -f '{{.RestartCount}}' "$container")"
done
sleep 30
for service in "${services[@]}"; do
  read -r container count <<< "${started[$service]}"
  if [ "$(docker inspect -f '{{.State.Status}} {{.RestartCount}}' "$container")" != "running $count" ]; then
    echo "$service restarted or stopped within 30s of starting" >&2
    exit 1
  fi
done

docker image prune -af

echo "==> Running: ${services[*]}"
