#!/bin/bash

# Runs the auth service from the compose file, .env and auth.env Terraform
# uploaded. Terraform re-runs this whenever any of them or anything else in its
# triggers changes, so every step must be safe over a live host.

set -euo pipefail

: "${DEPLOY_USER:?DEPLOY_USER is required}"
: "${DEPLOY_DIR:?DEPLOY_DIR is required}"
: "${STAGED_DIR:?STAGED_DIR is required}"
: "${PORT_GUARD:?PORT_GUARD is required}"
PRIVATE_ADDRESSES="${PRIVATE_ADDRESSES:-}"

# auth.env holds the credentials, so it goes however this ends
clear_staged() {
  rm -f "$STAGED_DIR"/*.yml "$STAGED_DIR/.env" "$STAGED_DIR/auth.env" "$STAGED_DIR/jwt-public.pem"
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
# replace the ones in use, so a refused deploy leaves auth as it was.
# --no-env-resolution keeps auth.env's credentials out of the model.
echo "==> Checking published ports"
compose_in "$STAGED_DIR" config --format json --no-env-resolution \
  | PRIVATE_ADDRESSES="$PRIVATE_ADDRESSES" python3 "$PORT_GUARD"

# A signing key that is not the other half of the key its tokens are verified
# with starts cleanly and then has every token refused. The private key goes
# from the file through the pipe, never through an argument.
echo "==> Checking the signing key against the key its tokens are verified with"
if ! signing="$(sed -n "s/^JWT_SECRET='\(.*\)'$/\1/p" "$STAGED_DIR/auth.env" | base64 -d | openssl pkey -pubout -outform DER 2>/dev/null | sha256sum)" \
  || ! verifying="$(openssl pkey -pubin -in "$STAGED_DIR/jwt-public.pem" -pubout -outform DER 2>/dev/null | sha256sum)"; then
  echo "Can't read the signing key in auth.env or the public key: both must be PEM keys" >&2
  exit 1
fi
if [ "$signing" != "$verifying" ]; then
  echo "auth's signing key is not the private half of the public key its tokens are verified with" >&2
  exit 1
fi

echo "==> Checking the database is reachable"
python3 - "$STAGED_DIR/auth.env" <<'PY'
import socket, sys
from urllib.parse import urlsplit

url = next(line.split("=", 1)[1].strip().strip("'") for line in open(sys.argv[1]) if line.startswith("DATABASE_URL="))
parts = urlsplit(url)
target = "%s:%s" % (parts.hostname, parts.port or 5432)
try:
    socket.create_connection((parts.hostname, parts.port or 5432), timeout=10).close()
except OSError as e:
    sys.exit("Can't reach the database at %s (%s). On a mesh host, check its key is in mesh_public_keys and the database host has applied it." % (target, e.strerror or e))
print("    %s reachable" % target)
PY

# Only an image not on the host yet: the reference is pinned, so a present
# image is the right one. Pulled before anything stops.
echo "==> Pulling the auth image if missing"
compose_in "$STAGED_DIR" pull --policy missing

# The migrations first, from the uploaded files, so a failed run stops the
# deploy before anything is replaced. `up` runs them again, with nothing left
# to apply and auth not waiting on them, and the deploy checks that run once
# auth is up.
echo "==> Running auth-migrate"
compose_in "$STAGED_DIR" run --rm --no-deps -T auth-migrate

install -d -m 0755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$(dirname "$DEPLOY_DIR")"
install -d -m 0750 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR"
for file in "$STAGED_DIR"/*.yml; do
  install -m 0644 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$file" "$DEPLOY_DIR/$(basename "$file")"
done
for file in "$STAGED_DIR/.env" "$STAGED_DIR/auth.env"; do
  install -m 0600 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$file" "$DEPLOY_DIR/$(basename "$file")"
done
clear_staged

echo "==> Starting auth"
compose_in "$DEPLOY_DIR" up -d

# not healthy within 300s, or restarted or not answering in the 30s after,
# fails the apply before old images are pruned. Docker takes three failed
# probes, 90s, to call a healthy container unhealthy, so the 30s ask auth's
# health route directly.
health() { docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$1"; }
i=0
until container="$(compose_in "$DEPLOY_DIR" ps -q auth 2>/dev/null)" \
  && [ -n "$container" ] \
  && [ "$(health "$container")" = healthy ]; do
  if [ -n "$container" ] && [ "$(health "$container")" = none ]; then
    echo "auth has no healthcheck, so the deploy can't tell when it is ready" >&2
    exit 1
  fi
  i=$((i + 1))
  if [ "$i" -ge 300 ]; then echo "auth not healthy after 300s" >&2; exit 1; fi
  sleep 1
done
restarts="$(docker inspect -f '{{.RestartCount}}' "$container")"
published="$(docker port "$container" 3030/tcp | head -n 1)"
for _ in 1 2 3 4 5 6; do
  sleep 5
  if ! python3 -c 'import sys, urllib.request; urllib.request.urlopen(sys.argv[1], timeout=4)' "http://$published/health" 2>/dev/null \
    || [ "$(health "$container") $(docker inspect -f '{{.RestartCount}}' "$container")" != "healthy $restarts" ]; then
    echo "auth restarted or stopped answering its health route within 30s of becoming healthy" >&2
    exit 1
  fi
done

# up's own auth-migrate container, not one a `run` left
project="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}' "$container")"
migrate="$(docker ps -aq --filter "label=com.docker.compose.project=$project" \
  --filter label=com.docker.compose.service=auth-migrate --filter label=com.docker.compose.oneoff=False)"
if [ -z "$migrate" ]; then
  echo "up started no auth-migrate, so the deploy can't tell its run succeeded" >&2
  exit 1
fi
if [ "$(timeout 300 docker wait "$migrate" || true)" != 0 ]; then
  docker logs --tail 5 "$migrate" >&2 || true
  echo "auth-migrate, run again by up, failed or ran past 300s" >&2
  exit 1
fi

docker image prune -af

echo "==> Running: auth"
