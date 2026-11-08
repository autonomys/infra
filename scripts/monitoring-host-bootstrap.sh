#!/bin/bash

# Brings a bare Ubuntu box up to spec as the fleet monitoring host. Runs after
# scripts/installer.sh, which owns docker. Terraform re-runs it whenever it
# changes, so every step must be safe over a live host.

set -euo pipefail

: "${MONITORING_USER:?MONITORING_USER is required}"
: "${MONITORING_DATA_DIR:?MONITORING_DATA_DIR is required}"

# the uid the grafana/loki image runs as
LOKI_UID=10001

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing base packages"
apt-get update -y
apt-get install -y \
  ca-certificates \
  curl \
  fail2ban \
  smartmontools \
  ufw \
  unattended-upgrades

echo "==> Setting timezone to UTC"
timedatectl set-timezone UTC

# The provider's image ships grub-efi-amd64 even on BIOS boxes, so a GRUB upgrade
# refreshes the modules in /boot without rewriting the boot code on either disk,
# and the mismatch can leave the box unbootable. grub-pc re-runs grub-install on
# every disk in install_devices whenever it is upgraded.
if [ ! -d /sys/firmware/efi ]; then
  boot_disks=()
  for part in $(mdadm --detail "$(findmnt -no SOURCE /boot)" | awk '/active sync/ {print $NF}'); do
    # -d, or lsblk also lists the md array built on the partition
    disk="/dev/$(lsblk -dno PKNAME "$part")"
    stable="$disk"
    for link in /dev/disk/by-id/ata-* /dev/disk/by-id/nvme-*; do
      if [ -e "$link" ] && [ "$(readlink -f "$link")" = "$disk" ]; then
        stable="$link"
        break
      fi
    done
    boot_disks+=("$stable")
  done
  if [ "${#boot_disks[@]}" -lt 2 ]; then
    echo "Expected /boot on RAID 1 across two disks, found ${#boot_disks[@]}" >&2
    exit 1
  fi

  wanted="$(printf '%s\n' "${boot_disks[@]}" | sort | paste -sd, - | sed 's/,/, /g')"
  current="$(debconf-show grub-pc 2>/dev/null | sed -n 's/^\* grub-pc\/install_devices: //p' | tr -d ' ' | tr ',' '\n' | sort | paste -sd, - | sed 's/,/, /g')"

  if ! dpkg-query -W -f='${Status}' grub-pc 2>/dev/null | grep -q 'install ok installed' \
    || [ "$wanted" != "$current" ]; then
    echo "==> Installing GRUB to ${boot_disks[*]}"
    echo "grub-pc grub-pc/install_devices multiselect $wanted" | debconf-set-selections
    echo "grub-pc grub-pc/install_devices_empty boolean false" | debconf-set-selections
    apt-get install -y grub-pc
    dpkg-reconfigure -f noninteractive grub-pc
  fi
fi

echo "==> Configuring firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'ssh'

# 80 and 443 only from Cloudflare, so the origin can't be found by scanning for the
# certificate it serves. Let's Encrypt's HTTP-01 checks also arrive through
# Cloudflare. Traefik runs in host networking for these rules to apply to it.
# Each family is fetched separately so a failed fetch stops the script
# instead of leaving a partial list.
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

echo "==> Preparing data directories"
install -d -m 0755 -o root -g root "$MONITORING_DATA_DIR"
install -d -m 0750 -o "$LOKI_UID" -g "$LOKI_UID" "$MONITORING_DATA_DIR/loki"
install -d -m 0700 -o root -g root "$MONITORING_DATA_DIR/traefik"

echo "==> Adding $MONITORING_USER to the docker group"
usermod -aG docker "$MONITORING_USER"

echo "==> Bootstrap complete"
