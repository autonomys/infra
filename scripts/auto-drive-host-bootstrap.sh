#!/bin/bash

# Brings a bare Ubuntu box up to spec as an auto-drive host. Runs after
# scripts/installer.sh, which owns docker and the loki log driver. Terraform re-runs
# it whenever it changes, so every step must be safe over a live host.

set -euo pipefail

: "${AUTO_DRIVE_USER:?AUTO_DRIVE_USER is required}"
: "${AUTO_DRIVE_DEPLOY_DIR:?AUTO_DRIVE_DEPLOY_DIR is required}"
: "${AUTO_DRIVE_REPO_REF:?AUTO_DRIVE_REPO_REF is required}"
: "${PRIMARY_DOMAIN:?PRIMARY_DOMAIN is required}"
: "${DOWNLOAD_DOMAIN:?DOWNLOAD_DOMAIN is required}"
: "${LETSENCRYPT_EMAIL:?LETSENCRYPT_EMAIL is required}"
: "${CLOUDFLARE_CREDENTIALS_SRC:?CLOUDFLARE_CREDENTIALS_SRC is required}"

AUTO_DRIVE_REPO="${AUTO_DRIVE_REPO:-https://github.com/autonomys/auto-drive.git}"
CLOUDFLARE_CREDENTIALS=/root/.secrets/cloudflare.ini

# kept out of the deploy directory itself so the forced checkout below can never
# touch the files deployed alongside it: .env and the compose file
AUTO_DRIVE_SRC_DIR="$AUTO_DRIVE_DEPLOY_DIR/src"

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing base packages"
apt-get update -y
apt-get install -y \
  ca-certificates \
  certbot \
  curl \
  fail2ban \
  git \
  nginx \
  python3-certbot-dns-cloudflare \
  ufw \
  unattended-upgrades

echo "==> Setting timezone to UTC"
timedatectl set-timezone UTC

echo "==> Configuring firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'ssh'

# 80 and 443 only from Cloudflare, so the origin can't be found by scanning for the
# certificate it serves. Each family is fetched separately so a failed fetch stops
# the script instead of leaving a partial list.
cloudflare_v4="$(curl -fsSL --retry 3 https://www.cloudflare.com/ips-v4)"
cloudflare_v6="$(curl -fsSL --retry 3 https://www.cloudflare.com/ips-v6)"
cloudflare_ranges=()
for cidr in $cloudflare_v4 $cloudflare_v6; do
  if [[ ! "$cidr" =~ ^[0-9a-f.:]+/[0-9]+$ ]]; then
    echo "Unexpected entry in Cloudflare's published ranges: $cidr" >&2
    exit 1
  fi
  cloudflare_ranges+=("$cidr")
done
if [ "${#cloudflare_ranges[@]}" -lt 10 ]; then
  echo "Only ${#cloudflare_ranges[@]} Cloudflare ranges fetched, refusing to apply" >&2
  exit 1
fi

ufw status numbered \
  | sed -n 's/^\[ *\([0-9][0-9]*\)\].*# cloudflare$/\1/p' \
  | sort -rn \
  | while read -r rule; do ufw --force delete "$rule" >/dev/null; done
for cidr in "${cloudflare_ranges[@]}"; do
  ufw allow proto tcp from "$cidr" to any port 80,443 comment 'cloudflare' >/dev/null
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

echo "==> Installing certbot cloudflare credentials"
install -d -m 0700 -o root -g root /root/.secrets
install -m 0600 -o root -g root "$CLOUDFLARE_CREDENTIALS_SRC" "$CLOUDFLARE_CREDENTIALS"
shred -u "$CLOUDFLARE_CREDENTIALS_SRC"

# DNS-01 so certificates can be issued before DNS is repointed at this box
for domain in "$PRIMARY_DOMAIN" "$DOWNLOAD_DOMAIN"; do
  if certbot certificates --cert-name "$domain" 2>/dev/null | grep -q "Certificate Name: $domain"; then
    echo "==> Certificate for $domain already present"
    continue
  fi

  echo "==> Issuing certificate for $domain"
  certbot certonly \
    --non-interactive \
    --agree-tos \
    --email "$LETSENCRYPT_EMAIL" \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$CLOUDFLARE_CREDENTIALS" \
    --dns-cloudflare-propagation-seconds 30 \
    --cert-name "$domain" \
    -d "$domain"
done

install -d -m 0755 /etc/letsencrypt/renewal-hooks/deploy
cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh <<'HOOK'
#!/bin/sh
systemctl reload nginx
HOOK
chmod 0755 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
systemctl enable --now certbot.timer

echo "==> Installing Infisical CLI"
if ! command -v infisical >/dev/null 2>&1; then
  curl -1sLf 'https://artifacts-cli.infisical.com/setup.deb.sh' | bash
  apt-get update -y
  apt-get install -y infisical
fi

echo "==> Preparing $AUTO_DRIVE_DEPLOY_DIR"
install -d -m 0755 -o "$AUTO_DRIVE_USER" -g "$AUTO_DRIVE_USER" "$AUTO_DRIVE_DEPLOY_DIR"
install -d -m 0755 -o "$AUTO_DRIVE_USER" -g "$AUTO_DRIVE_USER" "$AUTO_DRIVE_SRC_DIR"

# AUTO_DRIVE_REPO_REF must be a branch, tag or full SHA: short SHAs aren't fetchable
if [ ! -d "$AUTO_DRIVE_SRC_DIR/.git" ]; then
  echo "==> Initialising checkout of $AUTO_DRIVE_REPO"
  sudo -u "$AUTO_DRIVE_USER" git init -q "$AUTO_DRIVE_SRC_DIR"
  sudo -u "$AUTO_DRIVE_USER" git -C "$AUTO_DRIVE_SRC_DIR" remote add origin "$AUTO_DRIVE_REPO"
fi

echo "==> Checking out $AUTO_DRIVE_REPO_REF"
sudo -u "$AUTO_DRIVE_USER" git -C "$AUTO_DRIVE_SRC_DIR" fetch --depth 1 origin "$AUTO_DRIVE_REPO_REF"
sudo -u "$AUTO_DRIVE_USER" git -C "$AUTO_DRIVE_SRC_DIR" checkout -q --force FETCH_HEAD

echo "==> Adding $AUTO_DRIVE_USER to the docker group"
usermod -aG docker "$AUTO_DRIVE_USER"

echo "==> Bootstrap complete for $PRIMARY_DOMAIN"
