#!/bin/bash

# Brings a bare Ubuntu box up to the baseline every host role builds on. Runs
# after scripts/installer.sh, which owns docker and the loki log driver.
# Terraform re-runs it whenever it or its inputs change, so every step must be
# safe over a live host.

set -euo pipefail

: "${BOOTSTRAP_USER:?BOOTSTRAP_USER is required}"
: "${BOOTSTRAP_HOSTNAME:?BOOTSTRAP_HOSTNAME is required}"
PUBLIC_TCP_PORTS="${PUBLIC_TCP_PORTS:-}"
# space-separated protocol:port:source entries
PEER_RULES="${PEER_RULES:-}"

export DEBIAN_FRONTEND=noninteractive

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

echo "==> Setting hostname to $BOOTSTRAP_HOSTNAME"
hostnamectl set-hostname "$BOOTSTRAP_HOSTNAME"
if ! grep -qE "^[^#]*[[:space:]]$BOOTSTRAP_HOSTNAME([[:space:]]|$)" /etc/hosts; then
  echo "127.0.1.1 $BOOTSTRAP_HOSTNAME" >> /etc/hosts
fi

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
cat > /etc/ssh/sshd_config.d/99-hardening.conf <<'SSHD'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
SSHD
chmod 0644 /etc/ssh/sshd_config.d/99-hardening.conf

# sshd ignores the drop-in unless sshd_config includes it, and takes the first
# occurrence of each directive, so the Include has to come first
if ! grep -qE '^\s*Include\s+/etc/ssh/sshd_config\.d/\*\.conf' /etc/ssh/sshd_config; then
  echo "==> Adding missing sshd_config.d Include directive"
  sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config
fi

sshd -t
systemctl restart ssh 2>/dev/null || systemctl restart sshd

for setting in permitrootlogin:no passwordauthentication:no; do
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
