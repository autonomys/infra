#!/bin/bash

# Runs the Auto Drive backend services from the compose files and .env Terraform
# uploaded, behind host nginx with a Let's Encrypt certificate. Terraform re-runs
# this whenever any input changes, so every step must be safe over a live host.

set -euo pipefail

: "${DEPLOY_USER:?DEPLOY_USER is required}"
: "${DEPLOY_DIR:?DEPLOY_DIR is required}"
: "${STAGED_DIR:?STAGED_DIR is required}"
: "${PORT_GUARD:?PORT_GUARD is required}"
: "${CERT_NAME:?CERT_NAME is required}"
: "${CERT_DOMAINS:?CERT_DOMAINS is required}"
: "${LE_EMAIL:?LE_EMAIL is required}"
: "${LE_STAGING:?LE_STAGING is required}"
PRIVATE_ADDRESSES="${PRIVATE_ADDRESSES:-}"
NGINX_FILES=("$STAGED_DIR/nginx.conf" "$STAGED_DIR/site-bootstrap.conf" "$STAGED_DIR/site.conf")
SITE=/etc/nginx/sites-available/auto-drive
LIVE="/etc/letsencrypt/live/$CERT_NAME"

apt_timers_stopped=false
cleanup() {
  # the staged .env holds the credentials, so it goes however this ends
  rm -f "$STAGED_DIR"/*.yml "$STAGED_DIR/.env" "${NGINX_FILES[@]}"
  if $apt_timers_stopped; then systemctl start apt-daily.timer apt-daily-upgrade.timer; fi
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

# Compose takes the project, the files, the profiles and the values from the
# .env in the directory it runs in, as it does for anyone running it there by hand
compose_in() {
  local dir="$1"
  shift
  (cd "$dir" && docker compose "$@")
}

# Every check runs against the uploaded files, and only files that pass them
# replace the ones in use, so a refused deploy leaves the services as they were.
# hasura-assets is a one-shot copy, not a running service.
service_list="$(compose_in "$STAGED_DIR" config --services)"
mapfile -t services < <(grep -vx hasura-assets <<< "$service_list")

# Piped straight into the guard, never kept: the model holds the values the
# compose file interpolates from the .env, Hasura's credentials among them
echo "==> Checking published ports"
compose_in "$STAGED_DIR" config --format json --no-env-resolution \
  | PRIVATE_ADDRESSES="$PRIVATE_ADDRESSES" python3 "$PORT_GUARD"

echo "==> Checking the database and broker are reachable"
python3 - "$STAGED_DIR/.env" <<'PY'
import socket, sys
from urllib.parse import urlsplit

env = {}
for line in open(sys.argv[1]):
    key, _, value = line.rstrip("\n").partition("=")
    env[key] = value.strip("'")
failed = False
for key, default_port in (("DATABASE_URL", 5432), ("RABBITMQ_URL", 5672)):
    parts = urlsplit(env[key])
    port = parts.port or (5671 if parts.scheme == "amqps" else default_port)
    try:
        socket.create_connection((parts.hostname, port), timeout=10).close()
        print("    %s at %s:%s reachable" % (key, parts.hostname, port))
    except OSError as e:
        print("    %s at %s:%s unreachable (%s)" % (key, parts.hostname, port, e.strerror or e), file=sys.stderr)
        failed = True
if failed:
    sys.exit("On a mesh host, check its key is in mesh_public_keys and the services host has applied it.")
PY

# Only images not on the host yet: the references are pinned, so a present
# image is the right one. Pulled before anything stops.
echo "==> Pulling ${services[*]} if missing"
compose_in "$STAGED_DIR" pull --policy missing

packages=(nginx certbot python3-certbot-nginx)
if [ "$(dpkg-query -W -f='${Status}\n' "${packages[@]}" 2>/dev/null | grep -c 'install ok installed' || true)" -ne "${#packages[@]}" ]; then
  # the background apt timers hold locks apt-get won't wait for
  echo "==> Installing ${packages[*]}"
  systemctl stop apt-daily.timer apt-daily-upgrade.timer
  apt_timers_stopped=true
  systemd-run --quiet --property=After=apt-daily.service --property=After=apt-daily-upgrade.service --wait /bin/true
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
fi

if [ ! -s /etc/nginx/ssl/dhparam.pem ]; then
  echo "==> Generating /etc/nginx/ssl/dhparam.pem"
  install -d -m 0755 /etc/nginx/ssl
  openssl dhparam -out /etc/nginx/ssl/dhparam.pem.new 2048 2>/dev/null
  chmod 0644 /etc/nginx/ssl/dhparam.pem.new
  mv /etc/nginx/ssl/dhparam.pem.new /etc/nginx/ssl/dhparam.pem
fi

# Installs nginx.conf and the given site, and reloads nginx only if they pass
# `nginx -t`. Otherwise the files they replaced go back, so a rejected config
# never waits on disk for the next restart.
install_nginx() {
  local backup
  backup="$(mktemp -d)"
  cp -a /etc/nginx/nginx.conf "$backup/nginx.conf"
  if [ -f "$SITE" ]; then cp -a "$SITE" "$backup/site"; fi
  install -m 0644 "$STAGED_DIR/nginx.conf" /etc/nginx/nginx.conf
  install -m 0644 "$1" "$SITE"
  ln -sfn "$SITE" /etc/nginx/sites-enabled/auto-drive
  if ! nginx -t -q; then
    cp -a "$backup/nginx.conf" /etc/nginx/nginx.conf
    if [ -f "$backup/site" ]; then
      cp -a "$backup/site" "$SITE"
    else
      rm -f "$SITE" /etc/nginx/sites-enabled/auto-drive
    fi
    rm -rf "$backup"
    echo "nginx rejected the new configuration; the previous one is back in place" >&2
    exit 1
  fi
  rm -rf "$backup"
  rm -f /etc/nginx/sites-enabled/default
  systemctl enable -q nginx
  if systemctl is-active -q nginx; then systemctl reload nginx; else systemctl start nginx; fi
}

# the certificate's names, sorted, or nothing if there isn't one
cert_names() {
  [ -f "$LIVE/cert.pem" ] || return 0
  openssl x509 -in "$LIVE/cert.pem" -noout -ext subjectAltName \
    | grep -o 'DNS:[^,]*' | cut -d: -f2 | sort | paste -sd' ' -
}
wanted="$(tr ' ' '\n' <<< "$CERT_DOMAINS" | sort | paste -sd' ' -)"
have="$(cert_names)"
staging_issued=false
if [ -f "$LIVE/cert.pem" ] && openssl x509 -in "$LIVE/cert.pem" -noout -issuer | grep -q STAGING; then
  staging_issued=true
fi

if [ -n "$have" ] && [ "$have" != "$wanted" ]; then
  echo "The certificate $CERT_NAME covers '$have', not '$wanted'." >&2
  echo "Remove it with 'sudo certbot delete --cert-name $CERT_NAME' and apply again to issue one for the new names." >&2
  exit 1
fi

need_cert=false
if [ -z "$have" ]; then
  need_cert=true
elif [ "$LE_STAGING" = true ] && ! $staging_issued; then
  need_cert=true
elif [ "$LE_STAGING" = false ] && $staging_issued; then
  need_cert=true
fi

if $need_cert; then
  echo "==> Requesting a Let's Encrypt certificate for $wanted"
  # a site that already has a certificate keeps serving it while certbot works
  if [ -z "$have" ]; then install_nginx "$STAGED_DIR/site-bootstrap.conf"; fi
  certbot_args=(certonly --nginx --non-interactive --agree-tos --email "$LE_EMAIL"
    --cert-name "$CERT_NAME" --deploy-hook 'systemctl reload nginx')
  for domain in $CERT_DOMAINS; do certbot_args+=(-d "$domain"); done
  if [ "$LE_STAGING" = true ]; then certbot_args+=(--test-cert); fi
  if [ -n "$have" ]; then certbot_args+=(--force-renewal --break-my-certs); fi
  certbot "${certbot_args[@]}"
fi

echo "==> Installing the site"
install_nginx "$STAGED_DIR/site.conf"

install -d -m 0755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$(dirname "$DEPLOY_DIR")"
install -d -m 0750 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$DEPLOY_DIR"
for file in "$STAGED_DIR"/*.yml; do
  install -m 0644 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$file" "$DEPLOY_DIR/$(basename "$file")"
done
install -m 0600 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$STAGED_DIR/.env" "$DEPLOY_DIR/.env"
rm -f "$STAGED_DIR"/*.yml "$STAGED_DIR/.env" "${NGINX_FILES[@]}"

echo "==> Starting ${services[*]}"
compose_in "$DEPLOY_DIR" up -d --remove-orphans

if [[ " ${services[*]} " == *" hasura "* ]]; then
  assets="$(compose_in "$DEPLOY_DIR" ps -a -q hasura-assets)"
  if [ "$(docker inspect -f '{{.State.Status}} {{.State.ExitCode}}' "$assets")" != "exited 0" ]; then
    echo "hasura-assets did not copy Hasura's metadata from the backend image" >&2
    exit 1
  fi
fi

# a service that is not healthy within 300s, or restarts or turns unhealthy in
# the 30s after, fails the apply before old images are pruned
health() { docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$1"; }
declare -A started
for service in "${services[@]}"; do
  i=0
  until container="$(compose_in "$DEPLOY_DIR" ps -q "$service" 2>/dev/null)" \
    && [ -n "$container" ] \
    && [ "$(health "$container")" = healthy ]; do
    if [ -n "$container" ] && [ "$(health "$container")" = none ]; then
      echo "$service has no healthcheck, so the deploy can't tell when it is ready" >&2
      exit 1
    fi
    i=$((i + 1))
    if [ "$i" -ge 300 ]; then echo "$service not healthy after 300s" >&2; exit 1; fi
    sleep 1
  done
  started[$service]="$container $(docker inspect -f '{{.RestartCount}}' "$container")"
done
sleep 30
for service in "${services[@]}"; do
  read -r container count <<< "${started[$service]}"
  if [ "$(health "$container") $(docker inspect -f '{{.RestartCount}}' "$container")" != "healthy $count" ]; then
    echo "$service restarted or turned unhealthy within 30s of becoming healthy" >&2
    exit 1
  fi
done

echo "==> Checking the site answers through nginx"
for path in /api/health /hasura/healthz; do
  if [[ $path == /hasura/* && " ${services[*]} " != *" hasura "* ]]; then continue; fi
  # -k: a staging certificate isn't trusted, and this checks the path, not the chain
  curl -fsSk -o /dev/null --resolve "$CERT_NAME:443:127.0.0.1" "https://$CERT_NAME$path"
  echo "    https://$CERT_NAME$path OK"
done

docker image prune -af

echo "==> Running: ${services[*]}"
