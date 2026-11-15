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
# used only when the compose model has the DAG indexer
BACKUP_DIR="${BACKUP_DIR:-}"
export START_EMPTY="${START_EMPTY:-false}"
export ACCEPT_REWIND_TO="${ACCEPT_REWIND_TO:-}"
export ACCEPT_SCHEMA_SHA256="${ACCEPT_SCHEMA_SHA256:-}"

BACKUP_UNIT=/etc/systemd/system/auto-drive-gateway-db-backup

# the env files hold the credentials, so they go however this ends
trap 'rm -f "$STAGED_DIR"/*.yml "$STAGED_DIR"/*.env "$STAGED_DIR/.env" "$STAGED_DIR"/*.sh "$STAGED_DIR"/*.js' EXIT
trap 'exit 1' HUP INT TERM

# Compose takes the project, the files and the values from the .env in the
# directory it runs in, as it does for anyone running it there by hand
compose_in() {
  local dir="$1"
  shift
  (cd "$dir" && docker compose "$@")
}

# gateway-db.sh, in the backup service, with this deploy's overrides
gateway_db() {
  local dir="$1"
  shift
  compose_in "$dir" run --rm --no-deps -T -e START_EMPTY -e ACCEPT_REWIND_TO -e ACCEPT_SCHEMA_SHA256 gateway-db-backup "$@"
}

refuse() {
  echo "Refusing to deploy: $*" >&2
  exit 1
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

dag_indexer=false
for service in "${services[@]}"; do
  if [ "$service" = dag-indexer ]; then dag_indexer=true; fi
done
if $dag_indexer; then
  : "${BACKUP_DIR:?BACKUP_DIR is required with the DAG indexer}"
fi

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

# Before the migrations, as on a replaced database they would create what the
# indexes are then measured by
if $dag_indexer; then
  install -d -m 0700 "$BACKUP_DIR"
  install -d -m 0755 "$BACKUP_DIR/floor"
  echo "==> Checking the gateway database's progress against the last backup"
  gateway_db "$STAGED_DIR" guard
fi

# The indexer records its start block and creates its tables from schema.graphql
# on its first start, and never revisits either, so an image that differs from
# the database in either is refused before anything changes
if $dag_indexer; then
  echo "==> Checking the DAG indexer's image against its schema"
  indexer_image="$(python3 -c 'import json, sys; print(json.load(sys.stdin)["services"]["dag-indexer"]["image"])' <<< "$model")"
  manifest="$(python3 -c '
import json, sys
command = json.load(sys.stdin)["services"]["dag-indexer"]["command"]
print(command[command.index("-f") + 1])
' <<< "$model")"
  image_schema="$(docker run --rm --entrypoint sha256sum "$indexer_image" /app/schema.graphql | cut -d' ' -f1)"
  if ! image_start="$(docker run --rm --entrypoint sed "$indexer_image" -n 's/^ *startBlock: *//p' "$manifest")" \
    || [ -z "$image_start" ]; then
    refuse "the DAG indexer image has no start block in $manifest, so no manifest for this network"
  fi
  started="$(gateway_db "$STAGED_DIR" meta startHeight)"
  if [ -n "$started" ] && [ "$started" != "$image_start" ]; then
    refuse "the DAG index started at block $started, and the image's $manifest starts at $image_start. The indexer refuses a start block above its progress and ignores a lower one, so keep an image whose manifest starts at $started."
  fi
  recorded="$(gateway_db "$STAGED_DIR" schema-hash)"
  if [ "$recorded" != absent ] && [ -n "$recorded" ] && [ "$recorded" != "$image_schema" ] && [ "$ACCEPT_SCHEMA_SHA256" != "$image_schema" ]; then
    refuse "the image's schema.graphql is $image_schema, and the dag-indexer schema was created from $recorded. The indexer never alters an existing schema's tables, so bring them up to date by hand first, then set dag_indexer.accept_schema_sha256 = \"$image_schema\" for one apply."
  fi
fi

# Migrations first, one at a time, from the uploaded files: if one fails, `up`
# would already have replaced the app it belongs to with a container that never
# starts. `up` runs them again, with nothing left to apply. The backup runs on
# `up` only, after this deploy's changes.
for one_shot in "${one_shots[@]}"; do
  [ -n "$one_shot" ] && [ "$one_shot" != gateway-db-backup ] || continue
  echo "==> Running $one_shot"
  compose_in "$STAGED_DIR" run --rm --no-deps -T "$one_shot"
done

install -d -m 0755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$(dirname "$DEPLOY_DIR")"
install -d -m 0750 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR"
for file in "$STAGED_DIR"/*.yml "$STAGED_DIR"/*.sh "$STAGED_DIR"/*.js; do
  install -m 0644 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$file" "$DEPLOY_DIR/$(basename "$file")"
done
for file in "$STAGED_DIR"/*.env "$STAGED_DIR/.env"; do
  install -m 0600 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$file" "$DEPLOY_DIR/$(basename "$file")"
done
rm -f "$STAGED_DIR"/*.yml "$STAGED_DIR"/*.env "$STAGED_DIR/.env" "$STAGED_DIR"/*.sh "$STAGED_DIR"/*.js

# After every check, right before the indexer's start guard reads the floor
if $dag_indexer && { [ "$START_EMPTY" = true ] || [ -n "$ACCEPT_REWIND_TO" ]; }; then
  gateway_db "$DEPLOY_DIR" reset-floor
fi

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

if $dag_indexer; then
  # the check above compares later images with this; the indexer creates the
  # schema on its first start
  gateway_db "$DEPLOY_DIR" record-schema "$image_schema"

  echo "==> Scheduling the gateway database's nightly backup"
  cat > "$BACKUP_UNIT.service" <<EOF
[Unit]
Description=Back up the Auto Drive gateway database
Wants=docker.service
After=docker.service wg-quick@wg0.service

[Service]
Type=oneshot
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/bin/docker compose run --rm --no-deps -T gateway-db-backup
EOF
  cat > "$BACKUP_UNIT.timer" <<EOF
[Unit]
Description=Back up the Auto Drive gateway database nightly

[Timer]
OnCalendar=*-*-* 02:30:00 UTC
RandomizedDelaySec=15m
Persistent=true

[Install]
WantedBy=timers.target
EOF
  systemctl daemon-reload
  systemctl enable --now "$(basename "$BACKUP_UNIT").timer"
elif [ -e "$BACKUP_UNIT.timer" ]; then
  systemctl disable --now "$(basename "$BACKUP_UNIT").timer"
  rm -f "$BACKUP_UNIT.service" "$BACKUP_UNIT.timer"
  systemctl daemon-reload
fi

docker image prune -af

echo "==> Running: ${long_running[*]}"
