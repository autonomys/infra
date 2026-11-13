#!/bin/bash

# Runs the gateway's services from the compose files, .env and env files
# Terraform uploaded. Terraform re-runs this whenever any of them or anything
# else in its triggers changes, so every step must be safe over a live host.

set -euo pipefail
shopt -s nullglob

: "${DEPLOY_USER:?DEPLOY_USER is required}"
: "${DEPLOY_DIR:?DEPLOY_DIR is required}"
: "${STAGED_DIR:?STAGED_DIR is required}"
: "${PORT_GUARD:?PORT_GUARD is required}"
PUBLIC_TCP_PORTS="${PUBLIC_TCP_PORTS:-}"
PRIVATE_ADDRESSES="${PRIVATE_ADDRESSES:-}"

# the env files hold the credentials, so they go however this ends
trap 'rm -f "$STAGED_DIR"/*.yml "$STAGED_DIR"/*.env "$STAGED_DIR/.env"' EXIT
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
# --no-env-resolution keeps the env files' credentials out of the model.
model="$(compose_in "$STAGED_DIR" config --format json --no-env-resolution)"
service_list="$(python3 -c 'import json, sys; print("\n".join(json.load(sys.stdin)["services"]))' <<< "$model")"
mapfile -t services <<< "$service_list"
long_running_list="$(python3 -c '
import json, sys
services = json.load(sys.stdin)["services"]
print("\n".join(name for name, svc in services.items() if svc.get("restart", "no") != "no"))
' <<< "$model")"
mapfile -t long_running <<< "$long_running_list"
# in the order their depends_on gives, as `up` would run them
one_shot_list="$(python3 -c '
import json, sys
services = json.load(sys.stdin)["services"]
ordered = []
def visit(name):
    if name not in ordered:
        for dependency in services[name].get("depends_on") or {}:
            visit(dependency)
        ordered.append(name)
for name in sorted(services):
    visit(name)
print("\n".join(name for name in ordered if services[name].get("restart", "no") == "no"))
' <<< "$model")"
mapfile -t one_shots <<< "$one_shot_list"

echo "==> Checking published ports"
PUBLIC_TCP_PORTS="$PUBLIC_TCP_PORTS" PRIVATE_ADDRESSES="$PRIVATE_ADDRESSES" python3 "$PORT_GUARD" <<< "$model"

for address in $PRIVATE_ADDRESSES; do
  if ! ip -4 -o addr show | awk '{print $4}' | cut -d/ -f1 | grep -qxF "$address"; then
    echo "$address is not on this host, so the other mesh members can't reach these services: bring wg0 up first" >&2
    exit 1
  fi
done

# Only images not on the host yet, so a tag pushed again upstream can't recreate
# a service during an unrelated deploy. A tag changed in Terraform still pulls,
# before anything stops.
echo "==> Pulling ${services[*]} if missing"
compose_in "$STAGED_DIR" pull --policy missing

# Migrations first, one at a time, from the uploaded files: if one fails, `up`
# would already have replaced the app it belongs to with a container that never
# starts. `up` runs them again, with nothing left to apply.
for one_shot in "${one_shots[@]}"; do
  [ -n "$one_shot" ] || continue
  echo "==> Running $one_shot"
  compose_in "$STAGED_DIR" run --rm --no-deps -T "$one_shot"
done

install -d -m 0755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$(dirname "$DEPLOY_DIR")"
install -d -m 0750 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR"
for file in "$STAGED_DIR"/*.yml; do
  install -m 0644 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$file" "$DEPLOY_DIR/$(basename "$file")"
done
for file in "$STAGED_DIR"/*.env "$STAGED_DIR/.env"; do
  install -m 0600 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$file" "$DEPLOY_DIR/$(basename "$file")"
done
rm -f "$STAGED_DIR"/*.yml "$STAGED_DIR"/*.env "$STAGED_DIR/.env"

echo "==> Starting ${services[*]}"
compose_in "$DEPLOY_DIR" up -d

# a service that is not running, or restarts within 30s, fails the apply before
# old images are pruned
declare -A started
for service in "${long_running[@]}"; do
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
for service in "${long_running[@]}"; do
  read -r container count <<< "${started[$service]}"
  if [ "$(docker inspect -f '{{.State.Status}} {{.RestartCount}}' "$container")" != "running $count" ]; then
    echo "$service restarted or stopped within 30s of starting" >&2
    exit 1
  fi
done

docker image prune -af

echo "==> Running: ${long_running[*]}"
