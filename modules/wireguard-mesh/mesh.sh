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

export DEBIAN_FRONTEND=noninteractive

if ! command -v wg-quick >/dev/null 2>&1; then
  echo "==> Installing wireguard-tools"
  apt-get update -y
  apt-get install -y wireguard-tools
fi

install -d -m 0700 -o root -g root /etc/wireguard
if [ ! -s "$KEY" ]; then
  echo "==> Generating this host's mesh key"
  (umask 077 && wg genkey > "$KEY.new")
  mv "$KEY.new" "$KEY"
fi
chmod 0600 "$KEY"

# Peers can change in place without dropping traffic; anything above the first
# [Peer] needs the interface brought down and up again. Down comes before the
# new config is installed, so the old config's PreDown is the one that runs.
interface_section() { sed '/^\[Peer\]/,$d' "$1" 2>/dev/null || true; }
if [ "$(interface_section "$CONF")" != "$(interface_section "$MESH_CONFIG_SRC")" ] \
  && systemctl is-active --quiet "$UNIT"; then
  echo "==> Stopping wg0 to change its interface settings"
  systemctl stop "$UNIT"
fi
install -m 0600 -o root -g root "$MESH_CONFIG_SRC" "$CONF"
rm -f "$MESH_CONFIG_SRC"

# Containers that publish on the mesh address fail to start if wg0 isn't up
# yet. Takes effect from the next boot; Docker is not restarted here.
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
  # syncconf clears the private key when the config it is given has none, so
  # feed the key in; printf is a builtin, keeping it out of any process's argv
  wg syncconf wg0 <(
    printf '[Interface]\nPrivateKey = %s\n' "$(cat "$KEY")"
    wg-quick strip wg0 | sed '/^\[Interface\]$/d'
  )
fi

got="$(ip -4 -o addr show dev wg0 | awk '{print $4}' | cut -d/ -f1)"
if [ "$got" != "$MESH_ADDRESS" ]; then
  echo "wg0 has address '$got', expected '$MESH_ADDRESS'" >&2
  exit 1
fi

echo "==> wg0 is up on $MESH_ADDRESS with $(wg show wg0 peers | grep -c . || true) peer(s)"
echo "==> This host's mesh public key: $(wg show wg0 public-key)"
