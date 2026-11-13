#!/bin/bash

# Runs the backend's database migrations from the backend image, before any
# backend service starts on it. Terraform re-runs this whenever the image
# changes; db-migrate applies only what the database lacks.

set -euo pipefail

: "${DEPLOY_USER:?DEPLOY_USER is required}"
: "${DEPLOY_DIR:?DEPLOY_DIR is required}"
: "${MIGRATE_ENV:?MIGRATE_ENV is required}"
: "${BACKEND_IMAGE:?BACKEND_IMAGE is required}"

# the staged env file holds the migration credentials, so it goes however this ends
trap 'rm -f "$MIGRATE_ENV"' EXIT
trap 'exit 1' HUP INT TERM

install -d -m 0755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$(dirname "$DEPLOY_DIR")"
install -d -m 0750 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR"

echo "==> Checking the database is reachable"
python3 - "$MIGRATE_ENV" <<'PY'
import socket, sys
from urllib.parse import urlsplit

url = next(line.split("=", 1)[1].strip() for line in open(sys.argv[1]) if line.startswith("DATABASE_URL="))
parts = urlsplit(url)
target = "%s:%s" % (parts.hostname, parts.port or 5432)
try:
    socket.create_connection((parts.hostname, parts.port or 5432), timeout=10).close()
except OSError as e:
    sys.exit("Can't reach the database at %s (%s). On a mesh host, check its key is in mesh_public_keys and the services host has applied it." % (target, e.strerror or e))
print("    %s reachable" % target)
PY

echo "==> Pulling $BACKEND_IMAGE if missing"
docker image inspect "$BACKEND_IMAGE" >/dev/null 2>&1 || docker pull -q "$BACKEND_IMAGE"

echo "==> Running the backend's migrations"
docker run --rm --env-file "$MIGRATE_ENV" "$BACKEND_IMAGE" yarn workspace backend db-migrate up

# what validate.sh checks against the running image
printf '%s\n' "$BACKEND_IMAGE" > "$DEPLOY_DIR/migrated-image"
chown "$DEPLOY_USER:$DEPLOY_USER" "$DEPLOY_DIR/migrated-image"
echo "==> Migrations applied for $BACKEND_IMAGE"
