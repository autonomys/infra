#!/bin/bash

# Brings a bare Ubuntu box up to the baseline every host role builds on.
# scripts/installer.sh owns docker and the loki log driver. Terraform re-runs
# this whenever it or its inputs change, so every step must be safe over a live
# host.

set -euo pipefail

: "${BOOTSTRAP_USER:?BOOTSTRAP_USER is required}"
: "${BOOTSTRAP_HOSTNAME:?BOOTSTRAP_HOSTNAME is required}"
: "${INSTALLER:?INSTALLER is required}"
PUBLIC_TCP_PORTS="${PUBLIC_TCP_PORTS:-}"
# space-separated protocol:port:source entries
PEER_RULES="${PEER_RULES:-}"

INSTALLER_MARKER=/var/lib/host-bootstrap/installer.md5

export DEBIAN_FRONTEND=noninteractive

# Before the installer: the loki plugin it starts has its own hostname namespace
# and labels logs with the name it started under. A host renamed after its
# plugin started keeps the old label until docker restarts.
echo "==> Setting hostname to $BOOTSTRAP_HOSTNAME"
hostnamectl set-hostname "$BOOTSTRAP_HOSTNAME"
if ! grep -qE "^[^#]*[[:space:]]$BOOTSTRAP_HOSTNAME([[:space:]]|$)" /etc/hosts; then
  echo "127.0.1.1 $BOOTSTRAP_HOSTNAME" >> /etc/hosts
fi

# installer.sh upgrades docker-ce whenever a newer package exists, which
# restarts dockerd and every container on the host. Run it only when docker is
# incomplete or installer.sh has changed since this host last ran it. A host
# with docker but no marker (built before the marker, or adopted) is taken as
# current rather than having its containers restarted on first contact.
docker_ready() {
  command -v docker >/dev/null 2>&1 \
    && docker compose version >/dev/null 2>&1 \
    && docker plugin inspect loki:latest >/dev/null 2>&1
}

installer_hash="$(md5sum "$INSTALLER" | cut -d' ' -f1)"
if ! docker_ready \
  || { [ -f "$INSTALLER_MARKER" ] && [ "$(cat "$INSTALLER_MARKER")" != "$installer_hash" ]; }; then
  echo "==> Running $INSTALLER"
  bash -e "$INSTALLER"
else
  echo "==> Docker already set up by this installer version, not re-running it"
fi
install -d -m 0755 /var/lib/host-bootstrap
echo "$installer_hash" > "$INSTALLER_MARKER"

echo "==> Installing base packages"
apt-get update -y
apt-get install -y \
  ca-certificates \
  curl \
  fail2ban \
  git \
  python3 \
  ufw \
  unattended-upgrades

echo "==> Setting timezone to UTC"
timedatectl set-timezone UTC

echo "==> Configuring firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'ssh'

# Docker-published ports bypass UFW, so these rules don't gate the role's
# containers; they keep `ufw status` an honest list of what is meant to be open.
ufw status numbered \
  | sed -n 's/^\[ *\([0-9][0-9]*\)\].*# role-\(port\|peer\)$/\1/p' \
  | sort -rn \
  | while read -r rule; do ufw --force delete "$rule" >/dev/null; done
for port in $PUBLIC_TCP_PORTS; do
  if [[ ! "$port" =~ ^[0-9]+$ ]]; then
    echo "Invalid port in PUBLIC_TCP_PORTS: $port" >&2
    exit 1
  fi
  ufw allow "$port/tcp" comment 'role-port' >/dev/null
done
for rule in $PEER_RULES; do
  IFS=: read -r protocol port source <<< "$rule"
  if [[ ! "$protocol" =~ ^(tcp|udp)$ || ! "$port" =~ ^[0-9]+$ || ! "$source" =~ ^[0-9.]+(/[0-9]+)?$ ]]; then
    echo "Invalid entry in PEER_RULES: $rule" >&2
    exit 1
  fi
  ufw allow proto "$protocol" from "$source" to any port "$port" comment 'role-peer' >/dev/null
done
ufw --force enable

# safe only because Terraform has already authenticated as the deploy user by key
echo "==> Hardening SSH"
# sshd keeps the first value it reads for each directive and loads drop-ins in
# name order, so this one has to sort first, ahead of files such as cloud-init's
# 50-cloud-init.conf. Bootstraps before that wrote it as 99-hardening.conf.
rm -f /etc/ssh/sshd_config.d/99-hardening.conf
cat > /etc/ssh/sshd_config.d/00-hardening.conf <<'SSHD'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
SSHD
chmod 0644 /etc/ssh/sshd_config.d/00-hardening.conf

# sshd ignores the drop-ins unless sshd_config includes them, and the Include
# has to come before any directive sshd_config sets itself
if ! grep -qE '^\s*Include\s+/etc/ssh/sshd_config\.d/\*\.conf' /etc/ssh/sshd_config; then
  echo "==> Adding missing sshd_config.d Include directive"
  sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config
fi

sshd -t
systemctl restart ssh 2>/dev/null || systemctl restart sshd

for setting in permitrootlogin:no passwordauthentication:no kbdinteractiveauthentication:no pubkeyauthentication:yes; do
  key="${setting%%:*}"
  want="${setting##*:}"
  got="$(sshd -T | awk -v k="$key" '$1 == k {print $2}')"
  if [ "$got" != "$want" ]; then
    echo "SSH hardening did not take effect: $key is '$got', expected '$want'" >&2
    exit 1
  fi
done

echo "==> Enabling fail2ban and unattended upgrades"
cat > /etc/fail2ban/jail.local <<'JAIL'
[sshd]
enabled = true
bantime = 1h
findtime = 10m
maxretry = 5
JAIL
chmod 0644 /etc/fail2ban/jail.local

cat > /etc/apt/apt.conf.d/50unattended-upgrades-local <<'APT'
Unattended-Upgrade::Automatic-Reboot "false";
APT
chmod 0644 /etc/apt/apt.conf.d/50unattended-upgrades-local

systemctl enable --now fail2ban
systemctl restart fail2ban
systemctl enable --now unattended-upgrades

echo "==> Installing Infisical CLI"
if ! command -v infisical >/dev/null 2>&1; then
  curl -1sLf 'https://artifacts-cli.infisical.com/setup.deb.sh' | bash
  apt-get update -y
  apt-get install -y infisical
fi

echo "==> Adding $BOOTSTRAP_USER to the docker group"
usermod -aG docker "$BOOTSTRAP_USER"

echo "==> Bootstrap complete for $BOOTSTRAP_HOSTNAME"
