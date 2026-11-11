#!/bin/bash

# Runs Postgres and RabbitMQ from the compose file Terraform rendered, then makes
# sure the listed databases exist and both services accept the credentials in
# their env files. Terraform re-runs this whenever any of those change, so every
# step must be safe over a live host.

set -euo pipefail

: "${DEPLOY_USER:?DEPLOY_USER is required}"
: "${DEPLOY_DIR:?DEPLOY_DIR is required}"
: "${STAGED_DIR:?STAGED_DIR is required}"
: "${COMPOSE_PROJECT:?COMPOSE_PROJECT is required}"
: "${MESH_ADDRESS:?MESH_ADDRESS is required}"
: "${PORT_GUARD:?PORT_GUARD is required}"
POSTGRES_DATABASES="${POSTGRES_DATABASES:-}"
SERVICES=(postgres rabbitmq)
STAGED=("$STAGED_DIR/compose.yml" "$STAGED_DIR/rabbitmq.conf" "$STAGED_DIR/postgres.env" "$STAGED_DIR/rabbitmq.env")

# the staged env files hold the credentials, so they go however this ends
trap 'rm -f "${STAGED[@]}"' EXIT
trap 'exit 1' HUP INT TERM

for db in $POSTGRES_DATABASES; do
  if [[ ! "$db" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "Invalid database name in POSTGRES_DATABASES: $db" >&2
    exit 1
  fi
done

install -d -m 0755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$(dirname "$DEPLOY_DIR")"
install -d -m 0750 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR"
install -m 0644 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$STAGED_DIR/compose.yml" "$DEPLOY_DIR/docker-compose.yml"
install -m 0644 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$STAGED_DIR/rabbitmq.conf" "$DEPLOY_DIR/rabbitmq.conf"
for name in postgres rabbitmq; do
  install -m 0600 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$STAGED_DIR/$name.env" "$DEPLOY_DIR/$name.env"
done
rm -f "${STAGED[@]}"

compose=(docker compose --project-name "$COMPOSE_PROJECT" -f "$DEPLOY_DIR/docker-compose.yml")

# --no-env-resolution keeps the env files' credentials out of the model
echo "==> Checking published ports"
"${compose[@]}" config --format json --no-env-resolution \
  | PRIVATE_ADDRESSES="$MESH_ADDRESS" python3 "$PORT_GUARD"

if ! ip -4 -o addr show | awk '{print $4}' | cut -d/ -f1 | grep -qxF "$MESH_ADDRESS"; then
  echo "$MESH_ADDRESS is not on this host, so the other mesh members can't reach these services: bring wg0 up first" >&2
  exit 1
fi

# Only images not on the host yet: the official images are rebuilt under the
# same tag, and a new digest would otherwise recreate the database during an
# unrelated deploy. A tag changed in main.tf still pulls, before anything stops.
echo "==> Pulling ${SERVICES[*]} if missing"
"${compose[@]}" pull --policy missing

echo "==> Starting ${SERVICES[*]}"
"${compose[@]}" up -d

# a service that is not healthy within 300s, or restarts or turns unhealthy in
# the 30s after, fails the apply before old images are pruned
declare -A started
for service in "${SERVICES[@]}"; do
  i=0
  until container="$("${compose[@]}" ps -q "$service" 2>/dev/null)" \
    && [ -n "$container" ] \
    && [ "$(docker inspect -f '{{.State.Health.Status}}' "$container")" = healthy ]; do
    i=$((i + 1))
    if [ "$i" -ge 300 ]; then echo "$service not healthy after 300s" >&2; exit 1; fi
    sleep 1
  done
  started[$service]="$container $(docker inspect -f '{{.RestartCount}}' "$container")"
done
sleep 30
for service in "${SERVICES[@]}"; do
  read -r container count <<< "${started[$service]}"
  if [ "$(docker inspect -f '{{.State.Health.Status}} {{.RestartCount}}' "$container")" != "healthy $count" ]; then
    echo "$service restarted or turned unhealthy within 30s of becoming healthy" >&2
    exit 1
  fi
done

# Both images apply their password only when their data is first created, so
# each is set again here from the container's own environment. The password
# never passes through this script or any process's arguments.
echo "==> Creating databases (${POSTGRES_DATABASES:-none}) and setting the Postgres password"
postgres="$("${compose[@]}" ps -q postgres)"
{
  for db in $POSTGRES_DATABASES; do
    echo "SELECT 'CREATE DATABASE $db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\\gexec"
  done
  # keeps the statement, password included, out of the server log if it fails
  echo "SET log_min_error_statement = panic;"
  echo '\getenv password POSTGRES_PASSWORD'
  echo "ALTER ROLE postgres PASSWORD :'password';"
} | docker exec -i "$postgres" psql -X -q -v ON_ERROR_STOP=1 -U postgres -d postgres

# rabbitmqctl change_password only takes the password as an argument, so the
# broker reads it itself. As the rabbitmq user, for the healthcheck's reason.
echo "==> Setting the RabbitMQ password"
rabbitmq="$("${compose[@]}" ps -q rabbitmq)"
if ! result="$(docker exec -u rabbitmq "$rabbitmq" rabbitmqctl -q eval '
  rabbit_auth_backend_internal:change_password(
    list_to_binary(os:getenv("RABBITMQ_DEFAULT_USER")),
    list_to_binary(os:getenv("RABBITMQ_DEFAULT_PASS")),
    <<"auto-drive-services deploy">>).' 2>&1)" || [ "$result" != ok ]; then
  echo "Could not set the RabbitMQ password: $result" >&2
  echo "The user is created on the broker's first start, so a changed username needs a fresh broker volume" >&2
  exit 1
fi

docker image prune -af

echo "==> Running: ${SERVICES[*]}"
