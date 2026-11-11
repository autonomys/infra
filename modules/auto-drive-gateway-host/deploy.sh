#!/bin/bash

# Starts the listed auto-files-gateway services from that repo's own compose
# files, checked out at a pinned ref. Terraform re-runs it whenever the ref, the
# images, the settings or the service list change.

set -euo pipefail

: "${DEPLOY_USER:?DEPLOY_USER is required}"
: "${DEPLOY_DIR:?DEPLOY_DIR is required}"
: "${GATEWAY_REPO:?GATEWAY_REPO is required}"
: "${GATEWAY_REPO_REF:?GATEWAY_REPO_REF is required}"
: "${GATEWAY_ENV_SRC:?GATEWAY_ENV_SRC is required}"
: "${GATEWAY_OVERRIDE_SRC:?GATEWAY_OVERRIDE_SRC is required}"
: "${COMPOSE_PROJECT:?COMPOSE_PROJECT is required}"
: "${COMPOSE_FILES:?COMPOSE_FILES is required}"
: "${COMPOSE_PROFILES:?COMPOSE_PROFILES is required}"
: "${SERVICES:?SERVICES is required}"
PUBLIC_TCP_PORTS="${PUBLIC_TCP_PORTS:-}"

CHECKOUT="$DEPLOY_DIR/auto-files-gateway"
SETTINGS_ENV="$DEPLOY_DIR/auto-files-gateway.env"
OVERRIDE="$DEPLOY_DIR/auto-files-gateway.override.yml"
# written by the app's own secret fetch, not by Terraform; optional until a
# service that needs secrets is started
SECRETS_ENV="$DEPLOY_DIR/.env"

install -d -m 0755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR"

if [ ! -d "$CHECKOUT/.git" ]; then
  echo "==> Initialising checkout of $GATEWAY_REPO"
  sudo -u "$DEPLOY_USER" git init -q "$CHECKOUT"
  sudo -u "$DEPLOY_USER" git -C "$CHECKOUT" remote add origin "$GATEWAY_REPO"
fi
sudo -u "$DEPLOY_USER" git -C "$CHECKOUT" remote set-url origin "$GATEWAY_REPO"

# a branch, tag or full SHA: short SHAs aren't fetchable
echo "==> Checking out $GATEWAY_REPO_REF"
sudo -u "$DEPLOY_USER" git -C "$CHECKOUT" fetch -q --depth 1 origin "$GATEWAY_REPO_REF"
sudo -u "$DEPLOY_USER" git -C "$CHECKOUT" checkout -q --force FETCH_HEAD

install -m 0600 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$GATEWAY_ENV_SRC" "$SETTINGS_ENV"
install -m 0644 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$GATEWAY_OVERRIDE_SRC" "$OVERRIDE"
rm -f "$GATEWAY_ENV_SRC" "$GATEWAY_OVERRIDE_SRC"

compose=(docker compose --project-name "$COMPOSE_PROJECT")
for profile in $COMPOSE_PROFILES; do compose+=(--profile "$profile"); done
if [ -f "$SECRETS_ENV" ]; then compose+=(--env-file "$SECRETS_ENV"); fi
# last, so the settings Terraform manages win over anything in the secrets file
compose+=(--env-file "$SETTINGS_ENV")
for file in $COMPOSE_FILES; do compose+=(-f "$CHECKOUT/$file"); done
# the role's own override goes last, on top of upstream's files
compose+=(-f "$OVERRIDE")
read -r -a services <<< "$SERVICES"

# Docker-published ports bypass the firewall: refuse to start anything that
# would publish a port beyond loopback unless the role declares it public.
echo "==> Checking published ports"
config="$("${compose[@]}" config --format json "${services[@]}")"
PUBLIC_TCP_PORTS="$PUBLIC_TCP_PORTS" python3 -c '
import json, os, sys
allowed = set(os.environ["PUBLIC_TCP_PORTS"].split())
bad = []
for name, svc in json.load(sys.stdin)["services"].items():
    for port in svc.get("ports", []):
        host_ip = port.get("host_ip") or "0.0.0.0"
        published = str(port.get("published"))
        protocol = port.get("protocol", "tcp")
        if host_ip in ("127.0.0.1", "::1"):
            continue
        if published in allowed and protocol == "tcp":
            continue
        bad.append("%s: %s:%s/%s" % (name, host_ip, published, protocol))
if bad:
    print("Refusing to deploy, these ports would be published beyond loopback:", *bad, sep="\n  ", file=sys.stderr)
    sys.exit(1)
' <<< "$config"

# pull before anything stops, so a failed pull leaves the running services untouched
echo "==> Pulling ${services[*]}"
"${compose[@]}" pull "${services[@]}"

echo "==> Starting ${services[*]}"
"${compose[@]}" up -d "${services[@]}"

# a service that is not running, or restarts within 30s, fails the apply before
# old images are pruned
declare -A restarts
for service in "${services[@]}"; do
  i=0
  until container="$("${compose[@]}" ps -q "$service" 2>/dev/null)" \
    && [ -n "$container" ] \
    && [ "$(docker inspect -f '{{.State.Status}}' "$container")" = running ]; do
    i=$((i + 1))
    if [ "$i" -ge 300 ]; then echo "$service not running after 300s" >&2; exit 1; fi
    sleep 1
  done
  restarts[$service]="$container $(docker inspect -f '{{.RestartCount}}' "$container")"
done
sleep 30
for service in "${services[@]}"; do
  read -r container count <<< "${restarts[$service]}"
  if [ "$(docker inspect -f '{{.State.Status}} {{.RestartCount}}' "$container")" != "running $count" ]; then
    echo "$service restarted or stopped within 30s of starting" >&2
    exit 1
  fi
done

docker image prune -af

echo "==> Running: ${services[*]}"
