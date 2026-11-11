#!/bin/bash

# Brings up wg0, the host's interface on the private mesh, from the config
# Terraform rendered. The private key is generated here on first run and never
# leaves the host. Terraform re-runs this whenever the config changes, so every
# step must be safe over a live host.

set -euo pipefail

: "${MESH_CONFIG_SRC:?MESH_CONFIG_SRC is required}"
: "${MESH_ADDRESS:?MESH_ADDRESS is required}"

CONF=/etc/wireguard/wg0.conf
KEY=/etc/wireguard/wg0.key
UNIT=wg-quick@wg0
DOCKER_DROPIN=/etc/systemd/system/docker.service.d/10-wireguard-mesh.conf
SYSCTL_CONF=/etc/sysctl.d/90-wireguard-mesh.conf
APT_TIMERS=(apt-daily.timer apt-daily-upgrade.timer)

export DEBIAN_FRONTEND=noninteractive

apt_paused=""
new_conf=""
cleanup() {
  if [ -n "$new_conf" ]; then rm -f "$new_conf"; fi
  if [ -n "$apt_paused" ]; then systemctl start "${APT_TIMERS[@]}"; fi
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

if ! command -v wg-quick >/dev/null 2>&1; then
  echo "==> Installing wireguard-tools"
  # same apt timer pause as host-bootstrap, so no background apt run holds the
  # lock or starts mid-install
  systemctl stop "${APT_TIMERS[@]}"
  apt_paused=1
  systemd-run --quiet --property=After=apt-daily.service --property=After=apt-daily-upgrade.service --wait /bin/true
  apt-get update -y
  apt-get install -y wireguard-tools
  systemctl start "${APT_TIMERS[@]}"
  apt_paused=""
fi

install -d -m 0700 -o root -g root /etc/wireguard
if [ ! -s "$KEY" ]; then
  echo "==> Generating this host's mesh key"
  (umask 077 && wg genkey > "$KEY.new")
  mv "$KEY.new" "$KEY"
fi
chmod 0600 "$KEY"

# Terraform's config has no private key. The host's goes in under [Interface],
# so wg-quick's own commands, reload included, keep it; printf is a builtin,
# keeping the key out of any process's argv.
if ! grep -qx '\[Interface\]' "$MESH_CONFIG_SRC"; then
  echo "$MESH_CONFIG_SRC has no [Interface] section" >&2
  exit 1
fi
key="$(cat "$KEY")"
new_conf="$(mktemp /etc/wireguard/.wg0.conf.XXXXXX)"
{
  sed '/^\[Interface\]$/q' "$MESH_CONFIG_SRC"
  printf 'PrivateKey = %s\n' "$key"
  sed '0,/^\[Interface\]$/d' "$MESH_CONFIG_SRC"
} > "$new_conf"
unset key
rm -f "$MESH_CONFIG_SRC"

# Peers can change in place without dropping traffic; anything above the first
# [Peer] needs the interface brought down and up again. Down comes before the
# new config is installed, so the old config's PreDown is the one that runs.
interface_section() { sed '/^\[Peer\]/,$d' "$1" 2>/dev/null || true; }
if [ "$(interface_section "$CONF")" != "$(interface_section "$new_conf")" ] \
  && systemctl is-active --quiet "$UNIT"; then
  echo "==> Stopping wg0 to change its interface settings"
  systemctl stop "$UNIT"
fi
mv "$new_conf" "$CONF"
new_conf=""

# A container that publishes on the mesh address fails to start if wg0 isn't up,
# losing its loopback ports too, and Docker never retries it. Letting binds to
# an address the host doesn't have yet succeed means it starts regardless and
# answers on the mesh once wg0 is up; the address only accepts traffic while it
# is on wg0, where the DOCKER-USER rule guards it. Docker is also ordered after
# wg0, from the next boot; it is not restarted here.
echo "==> Allowing binds to the mesh address before wg0 is up"
cat > "$SYSCTL_CONF" <<EOF
net.ipv4.ip_nonlocal_bind = 1
EOF
chmod 0644 "$SYSCTL_CONF"
echo 1 > /proc/sys/net/ipv4/ip_nonlocal_bind

echo "==> Ordering docker after $UNIT"
install -d -m 0755 "$(dirname "$DOCKER_DROPIN")"
cat > "$DOCKER_DROPIN" <<EOF
[Unit]
Wants=$UNIT.service
After=$UNIT.service
EOF
chmod 0644 "$DOCKER_DROPIN"
systemctl daemon-reload

systemctl enable "$UNIT" >/dev/null 2>&1
if ! systemctl is-active --quiet "$UNIT"; then
  echo "==> Starting wg0"
  systemctl start "$UNIT"
else
  echo "==> Updating wg0 peers in place"
  # stripped first, so a failing strip stops here rather than handing syncconf
  # an empty config, which would remove the key and every peer
  stripped="$(wg-quick strip wg0)"
  wg syncconf wg0 <(printf '%s\n' "$stripped")
fi

got="$(ip -4 -o addr show dev wg0 | awk '{print $4}' | cut -d/ -f1)"
if [ "$got" != "$MESH_ADDRESS" ]; then
  echo "wg0 has address '$got', expected '$MESH_ADDRESS'" >&2
  exit 1
fi

echo "==> wg0 is up on $MESH_ADDRESS with $(wg show wg0 peers | grep -c . || true) peer(s)"
echo "==> This host's mesh public key: $(wg show wg0 public-key)"
